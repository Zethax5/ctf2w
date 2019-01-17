/*

Created by: Zethax
Document created on: January 17th, 2019
Last edit made on: January 17th, 2019
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

#define PLUGIN_NAME "tf_custom_booster_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in a custom ubercharge"
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

}

public Action:CW3_onAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  if(!StrEqual(plugin, PLUGIN_NAME))
    return;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(StrEqual(attrib, "ubercharge is booster shot"))
  {
    new String:values[2][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    action = Plugin_Handled;
  }
  
  return action;
}
