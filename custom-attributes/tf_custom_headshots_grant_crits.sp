/*

Created by: Zethax
Document created on: February 20th, 2019
Last edit made on: February 20th, 2019
Current version: v0.0

Attributes in this pack:
 None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_headshots_grant_crits"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that allows headshots to accumulate crits on any other weapon"
#define PLUGIN_VERS "v0.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:StoreCritOnHeadshot[2049];
new StoreCritOnHeadshot_Max[2049];
new StoreCritOnHeadshot_Crits[2049];
new bool:StoreCritOnHeadshot_KillRequired[2049];
new bool:StoreCritOnHeadshot_UseOnMiss[2049];
new bool:StoreCritOnHeadshot_IsMinicrits[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "headshots store crits"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		StoreCritOnHeadshot_Max[weapon] = StringToInt(values[0]);
		if(StringToInt(values[1]) >= 1)
			StoreCritOnHeadshot_KillRequired[weapon] = true;
		if(StringToInt(values[2]) >= 1)
			StoreCritOnHeadshot_UseOnMiss[weapon] = true;
		if(StringToInt(values[3]) >= 1)
			StoreCritOnHeadshot_IsMinicrits[weapon] = true;
		
		StoreCritOnHeadshot[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!StoreCritOnHeadshot[weapon])
		return Plugin_Continue;
		
	if(!StoreCritOnHeadshot_UseOnMiss[weapon])
		return Plugin_Continue;
	
	if(StoreCritOnHeadshot_Crits[weapon] > 0)
		StoreCritOnHeadshot_Crits[weapon]--;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && victim)
	{
		new secondary = GetPlayerWeaponSlot(attacker, 1);
		new melee = GetPlayerWeaponSlot(attacker, 2);
		if(StoreCritOnHeadshot[secondary] || StoreCritOnHeadshot[melee])
		{
			new wep = secondary;
			if(!StoreCritOnHeadshot[wep])
				wep = melee;
			
			if(damageCustom)
		}
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	StoreCritOnHeadshot[weapon]				 = false;
	StoreCritOnHeadshot_Max[weapon] 		 = 0;
	StoreCritOnHeadshot_Crits[weapon]		 = 0;
	StoreCritOnHeadshot_KillRequired[weapon] = false;
	StoreCritOnHeadshot_IsMinicrits[weapon]  = false;
	StoreCritOnHeadshot_UseOnMiss[weapon] 	 = false;
}
