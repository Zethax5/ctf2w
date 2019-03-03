/*

Created by: Zethax
Document created on: January 25th, 2019
Last edit made on: January 29th, 2019
Current version: v1.0

Attributes in this pack:
    - "jarate killer"
    	1) How long jarate lasts on killer
	
	When killed, the attacker will be jarated for X seconds.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_jarate_killer"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "A custom attribute plugin containing an attribute associated with jarate"
#define PLUGIN_VERS "v1.0"

//all the voice lines are a go
#include <sniper_domination_voice_lines>

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnInventoryApplication);
}

public OnMapStart() {

	for(new i = 0; i <= 4; i++)
		PrecacheSound(ScoutDominations[i], true);
	
	for(new i = 0; i <= 5; i++)
		PrecacheSound(SoldierDominations[i], true);
	
	for(new i = 0; i <= 4; i++)
		PrecacheSound(PyroDominations[i], true);
	
	for(new i = 0; i <= 5; i++)
		PrecacheSound(DemoDominations[i], true);
	
	for(new i = 0; i <= 6; i++)
		PrecacheSound(HeavyDominations[i], true);
	
	for(new i = 0; i <= 5; i++)
		PrecacheSound(EngiDominations[i], true);
	
	for(new i = 0; i <= 4; i++)
		PrecacheSound(MedicDominations[i], true);
	
	for(new i = 0; i <= 4; i++)
		PrecacheSound(SniperDominations[i], true);
	
	for(new i = 0; i <= 6; i++)
		PrecacheSound(SpyDominations[i], true);
}

new bool:JarateKiller[MAXPLAYERS + 1];
new Float:JarateKiller_Duration[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
	
	if(StrEqual(attrib, "jarate killer"))
	{
		JarateKiller_Duration[client] = StringToFloat(value);
		
		JarateKiller[client] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(JarateKiller[Victim])
	{
		TF2_AddCondition(attacker, TFCond_Jarated, JarateKiller_Duration[Victim], Victim);
		
		new TFClassType:class = TF2_GetPlayerClass(attacker);
		new voiceline;
		if(class == TFClass_Scout)
		{
			voiceline = GetRandomInt(0, 4);
			EmitSoundToClient(attacker, ScoutDominations[voiceline]);
		}
		else if(class == TFClass_Soldier)
		{
			voiceline = GetRandomInt(0, 5);
			EmitSoundToClient(attacker, SoldierDominations[voiceline]);
		}
		else if(class == TFClass_Pyro)
		{
			voiceline = GetRandomInt(0, 4);
			EmitSoundToClient(attacker, PyroDominations[voiceline]);
		}
		else if(class == TFClass_DemoMan)
		{
			voiceline = GetRandomInt(0, 5);
			EmitSoundToClient(attacker, DemoDominations[voiceline]);
		}
		else if(class == TFClass_Heavy)
		{
			voiceline = GetRandomInt(0, 6);
			EmitSoundToClient(attacker, HeavyDominations[voiceline]);
		}
		else if(class == TFClass_Engineer)
		{
			voiceline = GetRandomInt(0, 5);
			EmitSoundToClient(attacker, EngiDominations[voiceline]);
		}
		else if(class == TFClass_Medic)
		{
			voiceline = GetRandomInt(0, 4);
			EmitSoundToClient(attacker, MedicDominations[voiceline]);
		}
		else if(class == TFClass_Sniper)
		{
			voiceline = GetRandomInt(0, 4);
			EmitSoundToClient(attacker, SniperDominations[voiceline]);
		}
		else if(class == TFClass_Spy)
		{
			voiceline = GetRandomInt(0, 6);
			EmitSoundToClient(attacker, SpyDominations[voiceline]);
		}
		
		JarateKiller[Victim] = false;
		JarateKiller_Duration[Victim] = 0.0;
	}
}

public Action:OnInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		JarateKiller[client] = false;
		JarateKiller_Duration[client] = 0.0;
	}
}
