/*

Created by: Zethax
Document created on: January 24th, 2019
Last edit made on: January 24th, 2019
Current version: v0.0

Attributes in this pack:
 - "jarate explosion on dmg"
 	1) Radius of the explosion
	2) Duration of the applied jarate
	3) Minimum damage required to be taken in 1 hit to apply.
	
	When X or more damage is taken, the user creates a jarate blast around him.
	This effect can only trigger once.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_jarate_explosion_from_dmg"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute associated with jarate explosions"
#define PLUGIN_VERS "v0.0"

#define PARTICLE_PISSBLAST "peejar_impact"
#define SOUND_PISSBLAST ""

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
}

new bool:JarateExplosion[2049];
new Float:JarateExplosion_Radius[2049];
new Float:JarateExplosion_Duration[2049];
new Float:JarateExplosion_DmgThreshold[2049];
new bool:JarateExplosion_Primed[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
		
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(StrEqual(attrib, "jarate explosion on dmg"))
	{
		new String:values[3][10];
		ExplodeString(values, " ", sizeof(values), sizeof(values[]));
		
		JarateExplosion_Radius[weapon] = StringToFloat(values[0]);
		JarateExplosion_Duration[weapon] = StringToFloat(values[1]);
		JarateExplosion_DmgThreshold[weapon] = StringToFloat(values[2]);
		
		JarateExplosion[weapon] = true;
		JarateExplosion_Primed[weapon] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker && victim)
	{
		new secondary = GetPlayerWeaponSlot(victim, 1);
		if(secondary < 0 || secondary > 2048)
			return Plugin_Continue;
		
		if(JarateExplosion[secondary] && damage > JarateExplosion_DmgThreshold[secondary] && JarateExplosion_Primed[secondary])
		{
			ApplyRadiusEffects(victim, _, _, JarateExplosion_Radius[secondary], TFCond_Jarated, _, JarateExplosion_Duration[secondary], _, 2, false);
			SpawnParticle(victim, _, PARTICLE_PISSBLAST);
			EmitSoundToAll(SOUND_PISSBLAST, victim);
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	JarateExplosion[ent] = false;
	JarateExplosion_Radius[ent] = 0.0;
	JarateExplosion_Duration[ent] = 0.0;
	JarateExplosion_DmgThreshold[ent] = 0.0;
	JarateExplosion_Primed[ent] = false;
}

