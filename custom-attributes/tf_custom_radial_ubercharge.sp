/*

Previously when I made this the attribute was poorly made and caused lots of crashes, fun!
So I'm remaking it for the sake of not having to scroll through what feels like billions of lines of code
just to find the code associated with this attribute in there. 

Created by: Zethax
Document created on: January 22nd, 2019
Last edit made on: January 22nd, 2019
Current version: v1.0

Attributes in this pack:
	- "ubercharge is radial"
		1) Radius of the ubercharge
		2-4) Conditions to grant allies in the radius
		
		While ubercharged all nearby allies will gain X conditions

*/
	
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_radial_ubercharge"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in a custom attribute associated with the radial ubercharge"
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
	
	name				= PLUGIN_NAME,
	author			= PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version		 = PLUGIN_VERS,
	url				 = ""
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

new bool:RadialUbercharge[2049];
new Float:RadialUbercharge_Radius[2049];
new RadialUbercharge_Effect1[2049];
new RadialUbercharge_Effect2[2049];
new RadialUbercharge_Effect3[2049];
new Float:Boosted[MAXPLAYERS + 1];

//Used to keep track of when the ubercharge prethink ticked
//So we're not overloading the server every tick
new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "ubercharge is radial"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		RadialUbercharge_Radius[weapon] = StringToFloat(values[0]);
		RadialUbercharge_Effect1[weapon] = StringToInt(values[1]);
		RadialUbercharge_Effect2[weapon] = StringToInt(values[2]);
		RadialUbercharge_Effect3[weapon] = StringToInt(values[3]);
		
		RadialUbercharge[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public void OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
		
	if(Boosted[client] > 0.0 && GetEngineTime() >= Boosted[client] + 0.35)
	{	
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
		Boosted[client] = 0.0;
	}
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 | weapon > 2048)
		return;
	
	if(!RadialUbercharge[weapon])
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.25)
		RadialUbercharge_PreThink(client, weapon);
}

static void RadialUbercharge_PreThink(client, weapon)
{
	new ubercharged = GetEntProp(weapon, Prop_Send, "m_bChargeRelease");
	if(ubercharged)
	{
		new patient = GetMediGunPatient(client);
		if(IsValidClient(patient))
		{
			TF2_AddCondition(patient, TFCond:RadialUbercharge_Effect1[weapon], 0.33, client);
			TF2_AddCondition(patient, TFCond:RadialUbercharge_Effect2[weapon], 0.33, client);
			TF2_AddCondition(patient, TFCond:RadialUbercharge_Effect3[weapon], 0.33, client);
			Boosted[i] = GetEngineTime();
		}
		
		new Float:Pos1[3];
		GetClientAbsOrigin(client, Pos1);
		new Float:Pos2[3];
		new Float:distance;
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client))
			{
				GetClientAbsOrigin(i, Pos2);
				distance = GetVectorDistance(Pos1, Pos2);
				if(distance <= RadialUbercharge_Radius[weapon])
				{
					TF2_AddCondition(i, TFCond:RadialUbercharge_Effect1[weapon], 0.33, client);
					TF2_AddCondition(i, TFCond:RadialUbercharge_Effect2[weapon], 0.33, client);
					TF2_AddCondition(i, TFCond:RadialUbercharge_Effect3[weapon], 0.33, client);
					Boosted[i] = GetEngineTime();
				}
			}
		}
	}
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	RadialUbercharge[ent] = false;
	RadialUbercharge_Radius[ent] = 0.0;
	RadialUbercharge_Effect1[ent] = 0;
	RadialUbercharge_Effect2[ent] = 0;
	RadialUbercharge_Effect3[ent] = 0;
}

