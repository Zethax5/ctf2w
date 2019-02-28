/*

Created by: Zethax
Document created on: February 28th, 2019
Last edit made on: February 28th, 2019
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

#define PLUGIN_NAME "tf_custom_spy_detector"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that can debuff enemies while active"
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
	SDKHook(client, SDKHook_Think, OnClientThink);
}

new bool:Detector[2049];
new Float:Detector_Radius[2049];
new Float:Detector_DmgVuln[2049];
new Float:Detector_Duration[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
		
	if(StrEqual(attrib, "detection field while active"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		Detector_Radius[weapon] = StringToFloat(values[0]);
		Detector_DmgVuln[weapon] = StringToFloat(values[1]);
		Detector_Duration[weapon] = StringToFloat(values[2]);
		
		Detector[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnClientThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(Detector[weapon] && GetEngineTime() >= LastTick[client] + 0.1)
		Detector_Think(client, weapon);
}

void Detector_Think(client, weapon)
{
	new metal;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	Detector[ent] = false;
	Detector_Radius[ent] = 0.0;
	Detector_Duration[ent] = 0.0;
	Detector_DmgVuln[ent] = 0.0;
}
