/*

Created by: Zethax
Document created on: Friday, December 21st, 2018
Last edit made on: Friday, December 21st, 2018
Current version: v0.1

Attributes in this pack
  None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_AUTHOR   "Zethax"
#define PLUGIN_DESC     "Custom attributes used on custom Demoman weapons on the cTF2w servers."
#define PLUGIN_VERS     "v0.1"
#define PLUGIN_NAME     "Custom Attributes for Demoman Weapons by Zethax"

public Plugin:my_info() = {

  name        = PLUGIN_NAME,
  description = PLUGIN_DESC,
  author      = PLUGIN_AUTHOR,
  version     = PLUGIN_VERS,
  url         = ""
};

new bool:DrunkardsWrath[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib, const String:plugin, const String:value, bool:whileActive)
{
  new Action:action;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return Plugin_Continue;
  
  if(StrEqual(attrib, "drunkards wrath triggers"))
  {
    DrunkardsWrath[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}
