/*

Created by: Zethax
Document created on: January 14th, 2019
Last edit made on: January 14th, 2019
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

#define PLUGIN_NAME "tf_custom_evasion_meter"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds custom attributes associated with the evasion meter"
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
  SDKHook(client, SDKHook_PreThink, OnClientPreThink);
  SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:EvasionMeter[2049];
new Float:EvasionMeter_Gain[2049];
new Float:EvasionMeter_Subtract[2049];
new Float:EvasionMeter_SubtractMelee[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  
  if(!StrEqual(plugin, "tf_custom_evasion_meter"))
    return action;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return action;
  
  if(StrEqual(attrib, "gain evasion on hit"))
  {
    new String:values[3][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    EvasionMeter_Gain[weapon] = StringToFloat(values[0]);
    EvasionMeter_Subtract[weapon] = StringToFloat(values[1]);
    EvasionMeter_SubtractMelee[weapon] = StringToFloat(values[2]);
    
    EvasionMeter[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
  
  EvasionMeter[ent] = false;
  EvasionMeter_Gain[ent] = 0.0;
  EvasionMeter_Subtract[ent] = 0.0;
  EvasionMeter_SubtractMelee[ent] = 0.0;
}
