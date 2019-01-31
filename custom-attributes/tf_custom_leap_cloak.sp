/*

Created by: Zethax
Document created on: January 30th, 2019
Last edit made on: January 30th, 2019
Current version: v0.0

Attributes in this pack:
    - "cloak is leap"
	1) How much cloak to drain on use
	2) Vertical velocity to add
	3) Horizontal velocity multiplier
	4) Air control multiplier
	
	Cloak is replaced with a leap, which drains X amount of cloak.
	When cloak is used, the Spy will leap instead of go invisible, throwing him
	in the direction he's moving and causing him to jump upward.
	When leap is used, no fall damage is taken and air control is multiplied by Y.

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
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:LeapCloak[2049];
new Float:LeapCloak_Drain[2049];
new Float:LeapCloak_Mult[2049];
new Float:LeapCloak_AirControl[2049];
new Float:LeapCloak_JumpVel[2049];

new bool:CloakRemovesStatus[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(StrEqual(attrib, "cloak is leap"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		LeapCloak_Drain[weapon] = StringToFloat(values[0]);
		LeapCloak_JumpVel[weapon] = StringToFloat(values[1]);
		LeapCloak_Mult[weapon] = StringToFloat(values[2]);
		LeapCloak_AirControl[weapon] = StringToFloat(values[3]);
		
		LeapCloak[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "cloak removes negative status"))
	{
		CloakRemovesStatus[weapon] = true;
		action = Plugin_Handled;
	}
  
	return action;
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(TF2_GetPlayerClass(client) != TFClass_Spy)
		return;
	
	new cloak = GetPlayerWeaponSlot(client, 3);
	if(cloak < 0 || cloak > 2048)
		return;
		
	if(!LeapCloak[cloak] || !CloakRemovesStatus[cloak])
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		CustomCloak_PostThink(client, cloak);
}

public void CustomCloak_PostThink(client, cloak)
{
	if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{
		//removes negative status effects while cloaked, if the player doesn't have leap cloak
		//prevents the player from spamming the cloak to remove status effects for free
		if(CloakRemovesStatus[cloak] && !LeapCloak[cloak])
		{
			TF2_RemoveCondition(client, TFCond_OnFire);
			TF2_RemoveCondition(client, TFCond_MarkedForDeath);
			TF2_RemoveCondition(client, TFCond_Bleeding);
			TF2_RemoveCondition(client, TFCond_Slowed);
			TF2_RemoveCondition(client, TFCond_Dazed);
			TF2_RemoveCondition(client, TFCond_Jarated);
			TF2_RemoveCondition(client, TFCond_Milked);

		}
		
		new Float:m_flCloakMeter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
		if(LeapCloak[cloak] && m_flCloakMeter >= LeapCloak_Drain[cloak])
		{
			new Float:vel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
			vel[0] *= LeapCloak_Mult[cloak];
			vel[2] += LeapCloak_JumpVel[cloak];
			vel[1] *= LeapCloak_Mult[cloak];
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
			TF2Attrib_SetByName(cloak, "cancel falling damage", 1.0);
			TF2Attrib_SetByName(cloak, "increased air control", LeapCloak_AirControl[cloak]);
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", m_flCloakMeter - LeapCloak_Drain[cloak]);
			
			if(CloakRemovesStatus[cloak])
			{
				TF2_RemoveCondition(client, TFCond_OnFire);
				TF2_RemoveCondition(client, TFCond_MarkedForDeath);
				TF2_RemoveCondition(client, TFCond_Bleeding);
				TF2_RemoveCondition(client, TFCond_Slowed);
				TF2_RemoveCondition(client, TFCond_Dazed);
				TF2_RemoveCondition(client, TFCond_Jarated);
				TF2_RemoveCondition(client, TFCond_Milked);
			}
		}
		if(LeapCloak[cloak])
			TF2_RemoveCondition(client, TFCond_Cloaked);
	}
	if((GetClientFlags(client) & FL_ONGROUND) == FL_ONGROUND)
	{
		TF2Attrib_RemoveByName(cloak, "cancel falling damage");
		TF2Attrib_RemoveByName(cloak, "increased air control");
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	LeapCloak[ent] = false;
	LeapCloak_Drain[ent] = 0.0;
	LeapCloak_Mult[ent] = 0.0;
	LeapCloak_JumpVel[ent] = 0.0;
	LeapCloak_AirControl[ent] = 0.0;
	
	CloakRemovesStatus[ent] = false;
}
