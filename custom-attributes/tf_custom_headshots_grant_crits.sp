/*

Created by: Zethax
Document created on: February 20th, 2019
Last edit made on: March 2nd, 2019
Current version: v1.0

Attributes in this pack:
	- "headshots store crits"
		DISCLAIMER: Only works on secondary and melee weapons
		Note: Only value 1 is mandatory. All other values can be undefined.
		1) Maximum amount of crits that can be stored
		2) Whether or not a headshot kill is required to grant crits, or only the headshot
		3) Whether or not firing the weapon at all uses crits, rather than only on hit
		4) Whether or not the weapon accumulates minicrits instead of crits

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
#define PLUGIN_VERS "v1.0"

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
new StoreCritOnHeadshot_KillRequired[2049];
new StoreCritOnHeadshot_UseOnMiss[2049];
new StoreCritOnHeadshot_IsMinicrits[2049];

new Float:LastTick[MAXPLAYERS + 1];

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
		if(strlen(values[1]))
			StoreCritOnHeadshot_KillRequired[weapon] = StringToInt(values[1]);
		if(strlen(values[2]))
			StoreCritOnHeadshot_UseOnMiss[weapon] = StringToInt(values[2]);
		if(strlen(values[3]))
			StoreCritOnHeadshot_IsMinicrits[weapon] = StringToInt(values[3]);
		
		//Initializes ammo counter
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		StoreCritOnHeadshot[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!StoreCritOnHeadshot[weapon])
		return Plugin_Continue;
		
	if(StoreCritOnHeadshot_UseOnMiss[weapon])
	{
		if(StoreCritOnHeadshot_Crits[weapon] > 0)
			StoreCritOnHeadshot_Crits[weapon]--;
	}
		
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && victim)
	{
		new wep = GetPlayerWeaponSlot(attacker, 1);
		if(wep < 0 || !StoreCritOnHeadshot[wep])
			wep = GetPlayerWeaponSlot(attacker, 2);
		if(StoreCritOnHeadshot[wep])
		{
			if(damageCustom == TF_CUSTOM_HEADSHOT)
			{
				if(StoreCritOnHeadshot_KillRequired[wep])
				{
					if(damage >= GetClientHealth(victim))
					{
						StoreCritOnHeadshot_Crits[wep]++;
						if(StoreCritOnHeadshot_Crits[wep] > StoreCritOnHeadshot_Max[wep])
							StoreCritOnHeadshot_Crits[wep] = StoreCritOnHeadshot_Max[wep];
					}
				}
				else
				{
					StoreCritOnHeadshot_Crits[wep]++;
					if(StoreCritOnHeadshot_Crits[wep] > StoreCritOnHeadshot_Max[wep])
						StoreCritOnHeadshot_Crits[wep] = StoreCritOnHeadshot_Max[wep];
				}
			}
		}
		if(weapon > -1 && StoreCritOnHeadshot[weapon] && !StoreCritOnHeadshot_UseOnMiss[weapon])
		{
			StoreCritOnHeadshot_Crits[weapon]--;
			if(StoreCritOnHeadshot_Crits[weapon] < 0)
				StoreCritOnHeadshot_Crits[weapon] = 0;
		}
	}
	return Plugin_Continue;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!StoreCritOnHeadshot[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		StoreCritOnHeadshot_PreThink(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

static void StoreCritOnHeadshot_PreThink(client, weapon)
{
	if(StoreCritOnHeadshot_Crits[weapon] > 0)
	{
		if(StoreCritOnHeadshot_IsMinicrits[weapon])
			TF2_AddCondition(client, TFCond_Buffed, 0.3);
		else
			TF2_AddCondition(client, TFCond_CritCanteen, 0.3);
	}
	
	//Sets ammo display to show stacks
	SetEntProp(weapon, Prop_Send, "m_iClip1", StoreCritOnHeadshot_Crits[weapon]);
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	StoreCritOnHeadshot[ent]			  = false;
	StoreCritOnHeadshot_Max[ent] 		  = 0;
	StoreCritOnHeadshot_Crits[ent]		  = 0;
	StoreCritOnHeadshot_KillRequired[ent] = 0;
	StoreCritOnHeadshot_IsMinicrits[ent]  = 0;
	StoreCritOnHeadshot_UseOnMiss[ent] 	  = 0;
}
