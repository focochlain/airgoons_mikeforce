/*
	agoon_fnc_boobyTrapAO.sqf
	Author: Madman Theory
	Last Edited: 9/6/2021
	Version: 0.1

	Purpose: On execution, scatters traps around an active zone, making sure spawn locations are valid (ie, the traps will fit/won't tip over, etc.) 
	Factors in the relative power of each trap in terms of visibility, damage, and area of effect such that fewer deadly traps and more small, less lethal traps are spawned. 
	Additionally notifies OPFOR and civilians to avoid the AI blundering into them.

	Parameter(s):

			_zone: The AO to be trapped.
			_maxPerPlayer: The maximum number of traps to spawn for each player. No guarantee is offered that this ratio will be reached, as there may not be enough valid places for them all. Default is 1, 0 or less spawns exactly one trap.
			_budget: The total "value" of mines to use. Higher means more dangerous mines, as a rule. Default is 32.
			_uxo: If true, will consider spawning UXO in addition to the base SOG PF traps. Defaults to false.
			_antiTank: If true, will consider mining roads with AT mines. Defaults to true.


	Returns: 0 if successful, otherwise a value denoting which step failed.

	Example:
		
			["Saigon", 2, false, true, false] call airgoons_boobyTrapAO;

*/

params ["_zone", ["_maxPerPlayer", 4], ["_budget", 128], ["_uxo", true], ["_antiTank", false]]; //anti-tank is off by default until I develop something to fuck with helis

private _return = 0;
private _zoneCenter = getMarkerPos [_zone, true];
// For now, we'll assume AOs are always circular
private _zoneRadius = (getMarkerSize _zone) select 0;

//separate lists to make the flags work; values are currently provisional and will need to be adjusted for balace over time
//also, once the script is working well, look into using a HashMap for this in case it helps with perf
private _mineList = [["vn_mine_punji_01", 2], 0.5, ["vn_mine_punji_02", 1], 0.75, ["vn_mine_punji_03", 1], 0.45, ["vn_mine_tripwire_arty", 8], 0.15, ["vn_mine_tripwire_m16_04", 6], 0.25, ["vn_mine_tripwire_f1_04", 4], 0.3, ["vn_mine_tripwire_f1_02", 3], 0.35];
private _antiTankList = [["vn_mine_tm57", 4], 0.3, ["vn_mine_m15", 4], 0.2];
private _uxoList = [["ModuleBombCluster_01_UXO1_F", 4], 0.35, ["ModuleBombCluster_01_UXO2_F", 6], 0.25, ["ModuleBombCluster_01_UXO3_F", 3], 0.55, ["ModuleBombCluster_01_UXO4_F", 4], 0.5]; 

private _roads = [];

//allPlayers includes headless client AI because reasons so we need to filter them out
private _headlessClients = entities "HeadlessClient_F";
private _humanPlayers = allPlayers - _headlessClients;

if (_uxo) then {
	_mineList append _uxoList;
};

if (_antiTank) then {
	_mineList append _antiTankList;
	_roads = _zoneCenter nearRoads _zoneRadius;
};

//TODO: it might be possible to move _mine down in scope into the valid mine loop
private _mine = objNull;
private _mineCount = 0;

while {_budget > 0} do {
	private _validMineChoice = false;

	if (_mineCount == 1 and _maxPerPlayer <= 0) then {
		_return = -1;
		break;
	} else {
		if ((_mineCount / (count _humanPlayers)) >= _maxPerPlayer) then {
			_return = 2;
			break;
		};
	};
	
	while {!_validMineChoice} do {
		//using weights gives us a bit more control over what gets spawned
		private _trapChoice = selectRandomWeighted _mineList;
		
		if (_budget < (_trapChoice select 1)) then {
			//TODO: add code to remove the trap since we'll never be able to spawn it from here on
			continue;
		} else {
			_budget = _budget - (_trapChoice select 1);
			_validMineChoice = true;
		};

		if (_trapChoice in _antiTankList) then {
			private _selectedRoad = selectRandom _roads;

			_mine = createMine [(_trapChoice select 0), getPosATL _selectedRoad, [], 0.5];
			_mine setDir (random 360);

			/*TODO: Cheers to ralregorganon blanching at this for making me look up the finer points of Arma MP scripting; 
			I *think* the remoteExecs can be replaced with local spawn commands and we can instead remoteExecCall
			 the entire script to get the same effect more correctly and securely. Need to read up more on MP unit spawning first.
			*/
			//private _isDone = _mine remoteExec ["spawn", 0, true]; 
			//waituntil { sleep 1; scriptDone _isDone };

			east revealMine _mine;
			civilian revealMine _mine;
			_mineCount = _mineCount + 1;
		} else {
			private _validPosition = false;
			private _tries = 0;

			while {!_validPosition && _tries <= 5} do {
				//because of how the objectives are laid out, a uniform distribution works better for our purposes
				private _angle = random 360;
				private _distance = _zoneRadius * (sqrt (random 1));
				private _position = _zoneCenter getPos [_distance, _angle];

				//TODO: add better handling of the case where it can't find a valid positon

				private _candidatePosition =  [_position, 0, 20, 1, 0, 0.15, 0] call BIS_fnc_findSafePos; //TODO: profile this

				if (count _candidatePosition == 2) then {
					_validPosition = true;
					//because findSafePos returns a Position2D and createMine wants a PositionAGL, we need separately pass the x and y, and call getTerrainHeightASL for the z coord
					_mine = createMine [(_trapChoice select 0), [_candidatePosition select 0, _candidatePosition select 1, getTerrainHeightASL (_candidatePosition)], [], 0];
					_mine setDir (random 360);
					_mine setVehiclePosition [_candidatePosition, [], 0, "NONE"]; //possible candidate for optimization here

					//private _isDone = _mine remoteExec ["spawn", 0, true];
					//waituntil { sleep 1; scriptDone _isDone };

					east revealMine _mine;
					civilian revealMine _mine;
					_mineCount = _mineCount + 1;
				} else {
					//mitigate against infinite loops
					_tries = _tries + 1;
				};
			};

			if (_tries > 5) exitWith {
				echo "Repeatedly unable to find valid location for trap, aborting to avoid infinite loop";
				_budget = 0;
				_return = 1;
			};
		};
	};
};

_return;