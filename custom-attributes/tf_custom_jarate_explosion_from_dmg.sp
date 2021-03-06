/*

Created by: Zethax
Document created on: January 24th, 2019
Last edit made on: January 24th, 2019
Current version: v1.0

Attributes in this pack:
 - "jarate explosion on dmg"
 	1) Radius of the explosion
	2) Duration of the applied jarate
	3) Minimum damage required to be taken in 1 hit to apply.
	4) Recharge time
	
	When X or more damage is taken, the user creates a jarate blast around him.
	This effect can trigger once every X seconds.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_jarate_explosion_from_dmg"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute associated with jarate explosions"
#define PLUGIN_VERS "v1.0"

#define PARTICLE_PISSBLAST  "peejar_impact"
#define SOUND_PISSBLAST 	"weapons/jar_explode.wav"
#define SOUND_RECHARGE  	"player/recharged.wav"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnMapStart()
{
	PrecacheSound(SOUND_PISSBLAST, true);
	PrecacheParticle(PARTICLE_PISSBLAST);
	PrecacheSound(SOUND_RECHARGE, true);
}

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
	//because Crafting wanted it to reset after so long
	//ugh
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:JarateExplosion[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:JarateExplosion_Radius[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:JarateExplosion_Duration[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:JarateExplosion_DmgThreshold[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:JarateExplosion_Cooldown[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:JarateExplosion_Delay[MAXPLAYERS + 1][MAXSLOTS + 1];
new bool:JarateExplosion_Primed[MAXPLAYERS + 1][MAXSLOTS + 1];

//I don't know why I don't make this part of my .inc file at this point
//it's almost guaranteed to get used somewhere
new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
	
	if(StrEqual(attrib, "jarate explosion on dmg"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		JarateExplosion_Radius[client][slot] = StringToFloat(values[0]);
		JarateExplosion_Duration[client][slot] = StringToFloat(values[1]);
		JarateExplosion_DmgThreshold[client][slot] = StringToFloat(values[2]);
		JarateExplosion_Cooldown[client][slot] = StringToFloat(values[3]);
		
		JarateExplosion[client][slot] = true;
		JarateExplosion_Primed[client][slot] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker && victim)
	{
		new secondary = 1;
		if(JarateExplosion[victim][secondary])
		{
			if(damage > JarateExplosion_DmgThreshold[victim][secondary] && JarateExplosion_Primed[victim][secondary])
			{
				ApplyRadiusEffects(victim, _, _, JarateExplosion_Radius[victim][secondary], TFCond_Jarated, _, JarateExplosion_Duration[victim][secondary], _, 2, false);
				SpawnParticle(victim, PARTICLE_PISSBLAST);
				EmitSoundToAll(SOUND_PISSBLAST, victim);
				JarateExplosion_Primed[victim][secondary] = false;
				JarateExplosion_Delay[victim][secondary] = GetEngineTime();
			}
		}
	}
	return Plugin_Continue;
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new secondary = 1;
	if(!JarateExplosion[client][secondary])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		JarateExplosion_PostThink(client, secondary);
}

void JarateExplosion_PostThink(client, secondary)
{
	if(GetEngineTime() >= JarateExplosion_Delay[client][secondary] + JarateExplosion_Cooldown[client][secondary] && !JarateExplosion_Primed[client][secondary])
	{
		JarateExplosion_Primed[client][secondary] = true;
		EmitSoundToClient(client, SOUND_RECHARGE);
	}
}

public CW3_OnWeaponRemoved(slot, client)
{
	JarateExplosion[client][slot] = false;
	JarateExplosion_Radius[client][slot] = 0.0;
	JarateExplosion_Duration[client][slot] = 0.0;
	JarateExplosion_DmgThreshold[client][slot] = 0.0;
	JarateExplosion_Primed[client][slot] = false;
}

