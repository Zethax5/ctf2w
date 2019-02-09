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
	
}

public OnMapStart() {

	for(new i = 0; i < 7; i++)
	{
		PrecacheSound(ScoutDominations[i], true);
		PrecacheSound(SoldierDominations[i], true);
		PrecacheSound(PyroDominations[i], true);
		PrecacheSound(DemoDominations[i], true);
		PrecacheSound(HeavyDominations[i], true);
		PrecacheSound(EngiDominations[i], true);
		PrecacheSound(MedicDominations[i], true);
		PrecacheSound(SniperDominations[i], true);
		PrecacheSound(SpyDominations[i], true);
	}
}

new bool:JarateKiller[2049];
new Float:JarateKiller_Duration[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
		
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return Plugin_Continue;
	
	if(StrEqual(attrib, "jarate killer"))
	{
		JarateKiller_Duration[weapon] = StringToFloat(value);
		
		JarateKiller[weapon] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(attacker && Victim)
	{
		new secondary = GetPlayerWeaponSlot(Victim, 1);
		if(JarateKiller[secondary])
		{
			TF2_AddCondition(attacker, TFCond_Jarated, JarateKiller_Duration[secondary], Victim);
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
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	JarateKiller[ent] = false;
	JarateKiller_Duration[ent] = 0.0;
}
