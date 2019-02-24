
//All domination voice lines from Sniper

//Scout (5)
#define SNIPER_DOMINATE_SCOUT01 "vo/sniper_dominationscout01.mp3"
#define SNIPER_DOMINATE_SCOUT02 "vo/sniper_dominationscout02.mp3"
#define SNIPER_DOMINATE_SCOUT03 "vo/sniper_dominationscout03.mp3"
#define SNIPER_DOMINATE_SCOUT04 "vo/sniper_dominationscout04.mp3"
#define SNIPER_DOMINATE_SCOUT05 "vo/sniper_dominationscout05.mp3"

//Soldier (6)
#define SNIPER_DOMINATE_SOLDIER01 "vo/sniper_dominationsoldier01.mp3"
#define SNIPER_DOMINATE_SOLDIER02 "vo/sniper_dominationsoldier02.mp3"
#define SNIPER_DOMINATE_SOLDIER03 "vo/sniper_dominationsoldier03.mp3"
#define SNIPER_DOMINATE_SOLDIER04 "vo/sniper_dominationsoldier04.mp3"
#define SNIPER_DOMINATE_SOLDIER05 "vo/sniper_dominationsoldier05.mp3"
#define SNIPER_DOMINATE_SOLDIER06 "vo/sniper_dominationsoldier06.mp3"

//Pyro (5)
#define SNIPER_DOMINATE_PYRO01 "vo/sniper_dominationpyro01.mp3"
#define SNIPER_DOMINATE_PYRO02 "vo/sniper_dominationpyro02.mp3"
#define SNIPER_DOMINATE_PYRO03 "vo/sniper_dominationpyro03.mp3"
#define SNIPER_DOMINATE_PYRO04 "vo/sniper_dominationpyro04.mp3"
#define SNIPER_DOMINATE_PYRO05 "vo/sniper_dominationpyro05.mp3"

//Demoman (6)
#define SNIPER_DOMINATE_DEMO01 "vo/sniper_dominationdemoman01.mp3"
#define SNIPER_DOMINATE_DEMO02 "vo/sniper_dominationdemoman02.mp3"
#define SNIPER_DOMINATE_DEMO03 "vo/sniper_dominationdemoman03.mp3"
#define SNIPER_DOMINATE_DEMO04 "vo/sniper_dominationdemoman04.mp3"
#define SNIPER_DOMINATE_DEMO05 "vo/sniper_dominationdemoman05.mp3"
#define SNIPER_DOMINATE_DEMO06 "vo/sniper_dominationdemoman06.mp3"

//Heavy (7)
#define SNIPER_DOMINATE_HEAVY01 "vo/sniper_dominationheavy01.mp3"
#define SNIPER_DOMINATE_HEAVY02 "vo/sniper_dominationheavy02.mp3"
#define SNIPER_DOMINATE_HEAVY03 "vo/sniper_dominationheavy03.mp3"
#define SNIPER_DOMINATE_HEAVY04 "vo/sniper_dominationheavy04.mp3"
#define SNIPER_DOMINATE_HEAVY05 "vo/sniper_dominationheavy05.mp3"
#define SNIPER_DOMINATE_HEAVY06 "vo/sniper_dominationheavy06.mp3"
#define SNIPER_DOMINATE_HEAVY07 "vo/sniper_dominationheavy07.mp3"

//Engineer (6)
#define SNIPER_DOMINATE_ENGI01 "vo/sniper_dominationengineer01.mp3"
#define SNIPER_DOMINATE_ENGI02 "vo/sniper_dominationengineer02.mp3"
#define SNIPER_DOMINATE_ENGI03 "vo/sniper_dominationengineer03.mp3"
#define SNIPER_DOMINATE_ENGI04 "vo/sniper_dominationengineer04.mp3"
#define SNIPER_DOMINATE_ENGI05 "vo/sniper_dominationengineer05.mp3"
#define SNIPER_DOMINATE_ENGI06 "vo/sniper_dominationengineer06.mp3"

//Medic (5)
#define SNIPER_DOMINATE_MEDIC01 "vo/sniper_dominationmedic01.mp3"
#define SNIPER_DOMINATE_MEDIC02 "vo/sniper_dominationmedic02.mp3"
#define SNIPER_DOMINATE_MEDIC03 "vo/sniper_dominationmedic03.mp3"
#define SNIPER_DOMINATE_MEDIC04 "vo/sniper_dominationmedic04.mp3"
#define SNIPER_DOMINATE_MEDIC05 "vo/sniper_dominationmedic05.mp3"

//Sniper (5)
#define SNIPER_DOMINATE_SNIPER01 "vo/sniper_dominationsniper18.mp3"
#define SNIPER_DOMINATE_SNIPER02 "vo/sniper_dominationsniper19.mp3"
#define SNIPER_DOMINATE_SNIPER03 "vo/sniper_dominationsniper20.mp3"
#define SNIPER_DOMINATE_SNIPER04 "vo/sniper_dominationsniper21.mp3"
#define SNIPER_DOMINATE_SNIPER05 "vo/sniper_dominationsniper22.mp3"

//Spy (7)
#define SNIPER_DOMINATE_SPY01 "vo/sniper_dominationspy01.mp3"
#define SNIPER_DOMINATE_SPY02 "vo/sniper_dominationspy02.mp3"
#define SNIPER_DOMINATE_SPY03 "vo/sniper_dominationspy03.mp3"
#define SNIPER_DOMINATE_SPY04 "vo/sniper_dominationspy04.mp3"
#define SNIPER_DOMINATE_SPY05 "vo/sniper_dominationspy05.mp3"
#define SNIPER_DOMINATE_SPY06 "vo/sniper_dominationspy06.mp3"
#define SNIPER_DOMINATE_SPY07 "vo/sniper_dominationspy07.mp3"

new String:ScoutDominations[5][40] = {SNIPER_DOMINATE_SCOUT01, SNIPER_DOMINATE_SCOUT02, SNIPER_DOMINATE_SCOUT03, 
				SNIPER_DOMINATE_SCOUT04, SNIPER_DOMINATE_SCOUT05};
new String:SoldierDominations[6][40] = {SNIPER_DOMINATE_SOLDIER01, SNIPER_DOMINATE_SOLDIER02, SNIPER_DOMINATE_SOLDIER03, 
				SNIPER_DOMINATE_SOLDIER04, SNIPER_DOMINATE_SOLDIER05, SNIPER_DOMINATE_SOLDIER06};
new String:PyroDominations[5][32] = {SNIPER_DOMINATE_PYRO01, SNIPER_DOMINATE_PYRO02, SNIPER_DOMINATE_PYRO03, 
				SNIPER_DOMINATE_PYRO04, SNIPER_DOMINATE_PYRO05};
new String:DemoDominations[6][40] = {SNIPER_DOMINATE_DEMO01, SNIPER_DOMINATE_DEMO02, SNIPER_DOMINATE_DEMO03, 
				SNIPER_DOMINATE_DEMO04, SNIPER_DOMINATE_DEMO05, SNIPER_DOMINATE_DEMO06};
new String:HeavyDominations[7][32] = {SNIPER_DOMINATE_HEAVY01, SNIPER_DOMINATE_HEAVY02, SNIPER_DOMINATE_HEAVY03, 
				SNIPER_DOMINATE_HEAVY04, SNIPER_DOMINATE_HEAVY05, SNIPER_DOMINATE_HEAVY06, 
				SNIPER_DOMINATE_HEAVY07};
new String:EngiDominations[6][40] = {SNIPER_DOMINATE_ENGI01, SNIPER_DOMINATE_ENGI02, SNIPER_DOMINATE_ENGI03, 
				SNIPER_DOMINATE_ENGI04, SNIPER_DOMINATE_ENGI05, SNIPER_DOMINATE_ENGI06};
new String:MedicDominations[5][32] = {SNIPER_DOMINATE_MEDIC01, SNIPER_DOMINATE_MEDIC02, SNIPER_DOMINATE_MEDIC03, 
				SNIPER_DOMINATE_MEDIC04, SNIPER_DOMINATE_MEDIC05};
new String:SniperDominations[5][40] = {SNIPER_DOMINATE_SNIPER01, SNIPER_DOMINATE_SNIPER02, SNIPER_DOMINATE_SNIPER03, 
				SNIPER_DOMINATE_SNIPER04, SNIPER_DOMINATE_SNIPER05};
new String:SpyDominations[7][32] = {SNIPER_DOMINATE_SPY01, SNIPER_DOMINATE_SPY02, SNIPER_DOMINATE_SPY03, 
				SNIPER_DOMINATE_SPY04, SNIPER_DOMINATE_SPY05, SNIPER_DOMINATE_SPY06, 
				SNIPER_DOMINATE_SPY07 };
