/*
The previous version of this attribute was terribly made.
Using the ability associated with it was heavy on the server.
So, I'm remaking it.

Created by: Zethax
Document created on: January 16th, 2019
Last edit made on: January 16th, 2019
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

#define PLUGIN_NAME "tf_custom_building_ugrade"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Template"
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
  SDKHook(Client, SDKHook_PostThinkPost, OnClientPostThinkPost);
}

new bool:BuildingUpgrade[2049];
new Float:BuildingUpgrade_MaxCharge[2049];
new Float:BuildingUpgrade_SentryMult[2049];
new Float:BuildingUpgrade_Charge[2049];

//For keeping track of the owner of various buildings
new SentryOwner[MAXPLAYERS + 1];
new DispenserOwner[MAXPLAYERS + 1];
new TeleporterOwner[MAXPLAYERS + 1][2];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  if(!StrEqual(attrib, "tf_custom_building_upgrade"))
    return;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(StrEqual(attrib, "building upgrade attrib"))
  {
    new String:values[2][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    BuildingUpgrade_MaxCharge[weapon] = StringToFloat(values[0]);
    BuildingUpgrade_SentryMult[weapon] = StringToFloat(values[1]);
    
    BuildingUpgrade[weapon] = true;
    action = Plugin_Handled;
  }
  return action;
}

public Action:OnTakeDamageAlive()
{
  
}

public OnEntityCreated(ent, const String:classname[])
{
  if(ent < 0 || ent > 2048)
    return;
    
  new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
  if(!IsValidClient(owner))
    return;
  
  if(StrContains(classname, "obj_sentrygun"))
    SentryOwner[owner] = ent;
  if(StrContains(classname, "obj_dispenser))
    DispenserOwner[owner] = ent;
  if(StrContains(classname, "obj_teleporter"))
    TeleporterOwner[owner] = ent;
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
    
  BuildingUpgrade[ent] = false;
  BuildingUpgrade_Charge[ent] = 0.0;
  BuildingUpgrade_MaxCharge[ent] = 0.0;
  BuildingUpgrade_SentryMult[ent] = 0.0;
}
