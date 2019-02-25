/*

Created by: Zethax
Document created on: February 25th, 2019
Last edit made on: February 25th, 2019
Current version: v0.0

Attributes in this pack:
 None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_tank_goodness"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute associated with a tanky Heavy minigun."
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

new bool:TankUpgrades[2049];
new Float:TankUpgrades_Charge[2049];
new Float:TankUpgrades_MaxCharge[2049];
new Float:TankUpgrades_AddPerLevel[2049];
new Float:TankUpgrades_DmgResist[2049];
new TankUpgrades_Level[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(StrEqual(attrib, "tanking grants upgrades"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		TankUpgrades[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	
}
