/*

Created by: Zethax
Document created on: Thursday, December 20th, 2018
Last edit made on: Thursday, December 20th, 2018
Current version: v0.1

Attributes in this pack:
  None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <zethax>
#include <sdkhooks>

#define PLUGIN_AUTHOR  "Zethax"
#define PLUGIN_DESC    "All custom attributes for custom Soldier weapons on the cTF2w server."
#define PLUGIN_NAME    "New Soldier Attributes by Zethax"
#define PLUGIN_VERS    "v0.1"

public Plugin:my_info = {
  
  name        = PLUGIN_NAME,
  author      = PLUGIN_AUTHOR,
  description = PLUGIN_DESC,
  version     = PLUGIN_VERS,
  url         = ""
};

public OnPluginStart() {
  
  HookEvent("deploy_buff_banner", OnDeployBuffBanner);
  
  for (new i = 1; i < MaxClients; i++)
  {
    if(!IsValidClient(i))
      continue;
      
    OnClientPutInServer(i);
  }
}

public OnClientPutInServer(client) {
  
}

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  if(!StrEqual(plugin, "ctf2w-soldier-custom"))
    return Plugin_Continue;
  
  new Action:action;
  new weapon = GetPlayerWeaponSlot(client, slot);
  
  if(weapon < 0 || weapon > 2049)
    return Plugin_Continue;
    
  return action;
}
