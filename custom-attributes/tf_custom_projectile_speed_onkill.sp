/*

Created by: Zethax
Document created on: March 28th, 2019
Last edit made on: March 28th, 2019
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

#define PLUGIN_NAME "tf_custom_projectile_speed_onkill"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which grants stacking projectile speed on kill, among other speeds."
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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:SpeedOnKill[2049];
new Float:SpeedOnKill_FireSpd[2049];
new Float:SpeedOnKill_BlastRad[2049];
new Float:SpeedOnKill_ReloadSpd[2049];
new Float:SpeedOnKill_ProjectileSpd[2049];
new SpeedOnKill_MaxStacks[2049];
new SpeedOnKill_Stacks[2049];
new Float:SpeedOnKill_FastDecay[2049];
new Float:SpeedOnKill_Decay[2049];
new Float:SpeedOnKill_Tick[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "stack speed bonuses on kill"))
	{
		new String:values[7][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		SpeedOnKill_FireSpd[weapon] = StringToFloat(values[0]);
		SpeedOnKill_ReloadSpd[weapon] = StringToFloat(values[1]);
		SpeedOnKill_BlastRad[weapon] = StringToFloat(values[2]);
		SpeedOnKill_ProjectileSpd[weapon] = StringToFloat(values[3]);
		SpeedOnKill_MaxStacks[weapon] = StringToInt(values[4]);
		SpeedOnKill_Decay[weapon] = StringToFloat(values[5]);
		SpeedOnKill_FastDecay[weapon] = StringToInt(values[6]);
		
		SpeedOnKill[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	SpeedOnKill[ent] = false;
	SpeedOnKill_FireSpd[ent] = 0.0;
	SpeedOnKill_ReloadSpd[ent] = 0.0;
	SpeedOnKill_BlastRad[ent] = 0.0;
	SpeedOnKill_ProjectileSpd[ent] = 0.0;
	SpeedOnKill_MaxStacks[ent] = 0;
	SpeedOnKill_Decay[ent] = 0.0;
	SpeedOnKill_FastDecay[ent] = 0.0;
}
