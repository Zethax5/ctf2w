/*

I'm gonna try something new with this one.
I'm gonna take an approach similar to that of the dispenser minigun attributes.
These attributes will be modular and almost fully customizable.
I'll even see if I can make the attributes gained per level customizable.
I'ma have fun with this!

Created by: Zethax
Document created on: February 25th, 2019
Last edit made on: February 26th, 2019
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
new Float:TankUpgrades_DmgResistDur[2049];
new Float:TankUpgrades_AddDurPerLevel[2049];
new Float:TankUpgrades_DealtChargeRate[2049];
new Float:TankUpgrades_TakenChargeRate[2049];
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
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		TankUpgrades_MaxCharge[weapon] = StringToFloat(values[0]);
		TankUpgrades_AddPerLevel[weapon] = StringToFloat(values[1]);
		TankUpgrades_DmgResistDur[weapon] = StringToFloat(values[2]);
		TankUpgrades_AddDurPerLevel[weapon] = StringToFloat(values[3]);
		TankUpgrades_DealtChargeRate[weapon] = StringToFloat(values[4]);
		TankUpgrades_TakenChargeRate[weapon] = StringToFloat(values[5]);
		
		TankUpgrades[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

//add in OnTakeDamageAlive

//dunno what I'll need OnClientPreThink for, but it's there

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	TankUpgrades[ent] = false;
	TankUpgrades_Charge[ent] = 0.0;
	TankUpgrades_MaxCharge[ent] = 0.0;
	TankUpgrades_AddPerLevel[ent] = 0.0;
	TankUpgrades_DmgResistDur[ent] = 0.0;
	TankUpgrades_AddDurPerLevel[ent] = 0.0;
	TankUpgrades_DealtChargeRate[ent] = 0.0;
	TankUpgrades_TakenChargeRate[ent] = 0.0;
	TankUpgrades_Level[ent] = 0;
}
