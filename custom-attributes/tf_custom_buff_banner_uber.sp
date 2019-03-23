/*

Created by: Zethax
Document created on: March 23rd, 2019
Last edit made on: March 23rd, 2019
Current version: v1.0

Attributes in this pack:
	-> "ubercharge is buff banners"
		Any value activates
		Replaces standard ubercharge with all 3 buff banner effects.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_buff_banner_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which replaces the Medic's ubercharge with all 3 buff banners"
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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:BuffBannerUber[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "ubercharge is buff banners"))
	{
		BuffBannerUber[weapon] = true;
		TF2Attrib_SetByName(weapon, "medigun charge is crit boost", -1.0);
		action = Plugin_Handled;
	}
	
	return action;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!BuffBannerUber[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		BuffBannerUber_PreThink(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

void BuffBannerUber_PreThink(client, weapon)
{
	new ubercharged = GetEntProp(weapon, Prop_Send, "m_bChargeRelease");
	if(ubercharged)
	{
		new patient = GetMediGunPatient(client);
		if(patient > -1)
		{
			TF2_AddCondition(patient, TFCond_Buffed, 0.2, client);
			TF2_AddCondition(patient, TFCond:26, 0.2, client);
			TF2_AddCondition(patient, TFCond:29, 0.2, client);
		}
		TF2_AddCondition(client, TFCond_Buffed, 0.2, client);
		TF2_AddCondition(client, TFCond:26, 0.2, client);
		TF2_AddCondition(client, TFCond:29, 0.2, client);
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	BuffBannerUber[ent] = false;
}
