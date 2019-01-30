/*

Created by: Zethax
Document created on: January 30th, 2019
Last edit made on: January 30th, 2019
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

#define PLUGIN_NAME "tf_custom_leap_cloak"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute that turns Spy's cloak into a leap"
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

new bool:LeapCloak[2049];
new Float:LeapCloak_Drain[2049];
new Float:LeapCloak_Mult[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return;
	
	if(StrEqual(attrib, "cloak is leap"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		LeapCloak_Drain[weapon] = StringToFloat(values[0]);
		LeapCloak_Mult[weapon] = StringToFloat(values[1]);
		
		LeapCloak[weapon] = true;
		action = Plugin_Handled;
	}
  
	return action;
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	
}
