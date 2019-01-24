/*

Created by: Zethax
Document created on: January 24th, 2019
Last edit made on: January 24th, 2019
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
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_jarate_explosion_from_dmg"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute associated with jarate explosions"
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
}

new bool:JarateExplosion[2049];
new Float:JarateExplosion_Radius[2049];
new Float:JarateExplosion_Duration[2049];
new Float:JarateExplosion_MaxDmg[2049];
new bool:JarateExplosion_Primed[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
		
	new weapon = GetPlayerWeaponSlot(client, slot);
	
	if(StrEqual(attrib, "jarate explosion on dmg"))
	{
		new String:values[3][10];
		ExplodeString(values, " ", sizeof(values), sizeof(values[]));
		
		JarateExplosion_Radius[weapon] = StringToFloat(values[0]);
		JarateExplosion_Duration[weapon] = StringToFloat(values[1]);
		JarateExplosion_MaxDmg[weapon] = StringToFloat(values[2]);
		
		JarateExplosion[weapon] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive()
{
	if(attacker && victim)
	{
		new secondary = GetPlayerWeaponSlot(victim, 1);
		if(secondary < 0 || secondary > 2048)
			return Plugin_Continue;
		
		if(JarateExplosion[secondary] && damage > 30.0)
		{
			ApplyRadiusEffects(attacker, _, _, JarateExplosion_Radius[secondary], TFCond_Jarated, _, JarateExplosion_Duration[secondary], _, 2, false);
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	
}

