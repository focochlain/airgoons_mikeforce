/*
	boobyTrapAO.sqf
	Author: Madman Theory
	Last Edited: 8/6/2021
	Version: 0.1

	Purpose: On execution, scatters traps around an active zone, making sure spawn locations are valid (ie, the traps will fit/won't tip over, etc.) Factors in the relative power of each trap in terms of visibility, damage, and area of effect such that fewer deadly traps and more small, less lethal traps are spawned. Additionally notifies OPFOR to avoid the AI blundering into them.

	Parameter(s):

			_zone: The AO to be trapped.
			_maxPerPlayer: The maximum number of traps to spawn for each player. No guarantee is offered that this ratio will be reached, as there may not be enough valid places for them all. Default is 1, 0 or less spawns exactly one trap.
			_budget: The total "value" of mines to use. Higher means more dangerous mines, as a rule. Default is 32.
			_uxo: If true, will consider spawning UXO in addition to the base SOG PF traps. Defaults to false.
			_antiTank: If true, will consider mining roads with AT mines. Defaults to true.
			_comedyOption: When set to true, disregards all notion of balance, fairness or sanity and tries to put IEDs and giant UXO everywhere. Fun! Defaults to false for obvious reasons.


	Returns: true if successful, otherwise a value denoting which step failed.

	Example:
		
			["Saigon", 2, false, true, false] call airgoons_boobyTrapAO;

*/

params ["_zone", ["_maxPerPlayer", 1], ["_budget", 32], ["_uxo", false], ["_antiTank", true], ["_comedyOption", false]];

private _spawnPosition = [];
private _valid = false;

//separate lists to make the flags work; values are currently provisional and will need to be adjusted for balace over time

private _mineList = [["vn_mine_m14", 1], ["vn_mine_m16", 3], ["vn_mine_punji_01", 1], ["vn_mine_punji_02", 1], ["vn_mine_punji_03", 1], ["vn_mine_tripwire_arty", 8], ["vn_mine_tripwire_m16_04", 6], ["vn_mine_tripwire_f1_04", 4], ["vn_mine_tripwire_f1_02", 3]];
private _antiTankList = [["vn_mine_tm57", 4], ["vn_mine_m15", 4]];
private _uxoList = [["ModuleBombCluster_01_UXO1_F", 3], ["ModuleBombCluster_01_UXO2_F", 6], ["ModuleBombCluster_01_UXO3_F", 2], ["ModuleBombCluster_01_UXO4_F", 4]]; 

if (!_comedyOption) then {
	//UXO is just another kind of mine, mechanically, so no fancy logic needed
	if (_uxo) then {
		_mineList append _uxoList;
	};

	// need to special case AT mines because we want them on roads
	if (_antiTank) then {
		_mineList append _antiTankList;
	};

	while (_budget > 0) do {
		try {
			private _trap = selectRandom _mineList;
			if (isNil _trap) then {
				throw "no trap selected"
			};
			_budget = _budget - (_trap select 1);

		}
	};
} 
else {
	//may your higher power of choice have mercy on you, because the players sure won't

}   