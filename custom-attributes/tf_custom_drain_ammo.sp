/*

Created by: Zethax
Document created on: March 12th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "drain victim ammo on hit"
		1) % of primary ammo to drain on hit
		2) % of secondary ammo to drain on hit
		3) % of metal to drain on hit
		4) % of cloak to drain on hit
		5) % of ubercharge to drain on hit
		6) % of rage to drain on hit

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_drain_ammo"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which drains ammo on hit"
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
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:DrainAmmo[2049];
new Float:DrainAmmo_Primary[2049];
new Float:DrainAmmo_Secondary[2049];
new Float:DrainAmmo_Metal[2049];
new Float:DrainAmmo_Cloak[2049];
new Float:DrainAmmo_Ubercharge[2049];
new Float:DrainAmmo_Rage[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "drain victim ammo on hit"))
	{
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		DrainAmmo_Primary[weapon] = StringToFloat(values[0]);
		DrainAmmo_Secondary[weapon] = StringToFloat(values[1]);
		DrainAmmo_Metal[weapon] = StringToFloat(values[2]);
		DrainAmmo_Cloak[weapon] = StringToFloat(values[3]);
		//metal, cloak, and ammo drain I can understand
		//but this dude wants ubercharge and rage drain
		//wtf is this balance philosphy, because this shit is retarded
		DrainAmmo_Ubercharge[weapon] = StringToFloat(values[4]);
		DrainAmmo_Rage[weapon] = StringToFloat(values[5]);
		
		DrainAmmo[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(weapon > -1 && DrainAmmo[weapon])
	{
		//used to reduce drain based on damage falloff
		new Float:damageMultiplier = damage / 100.0;
		
		//All-class drains
		//Primary ammo --------------------------------------------------
		new PrimaryAmmo = GetAmmo_Weapon(victim, GetPlayerWeaponSlot(victim, 0));
		PrimaryAmmo = PrimaryAmmo - RoundFloat(PrimaryAmmo * (DrainAmmo_Primary[weapon] * damageMultiplier));
		if(PrimaryAmmo < 0)
			PrimaryAmmo = 0;
		SetAmmo_Weapon(victim, GetPlayerWeaponSlot(victim, 0), PrimaryAmmo);
		//Secondary ammo ------------------------------------------------
		new SecondaryAmmo = GetAmmo_Weapon(victim, GetPlayerWeaponSlot(victim, 1));
		SecondaryAmmo = SecondaryAmmo - RoundFloat(SecondaryAmmo * (DrainAmmo_Secondary[weapon] * damageMultiplier));
		if(SecondaryAmmo < 0)
			SecondaryAmmo = 0;
		SetAmmo_Weapon(victim, GetPlayerWeaponSlot(victim, 1), SecondaryAmmo);
		//Rage drain ----------------------------------------------------
		new Float:Rage = GetEntPropFloat(victim, Prop_Send, "m_flRageMeter");
		if(DrainAmmo_Rage[weapon] > 1.0)
			Rage -= DrainAmmo_Rage[weapon] * damageMultiplier;
		else
			Rage *= DrainAmmo_Rage[weapon] * damageMultiplier;
		if(Rage < 0.0)
			Rage = 0.0;
		SetEntPropFloat(victim, Prop_Send, "m_flRageMeter", Rage);
		
		//Class specific drains.
		//Engineer metal ------------------------------------------------
		if(TF2_GetPlayerClass(victim) == TFClass_Engineer)
		{
			new Metal = GetClientMetal(victim);
			Metal = Metal - RoundFloat(Metal * (DrainAmmo_Metal[weapon] * damageMultiplier));
			if(Metal < 0)
				Metal = 0;
			SetClientMetal(victim, Metal);
		}
		//Medic Ubercharge ----------------------------------------------
		if(TF2_GetPlayerClass(victim) == TFClass_Medic)
		{
			new secondary = GetPlayerWeaponSlot(victim, 1);
			new Float:Ubercharge = GetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel");
			Ubercharge = Ubercharge - (Ubercharge * (DrainAmmo_Ubercharge[weapon] * damageMultiplier));
			if(Ubercharge < 0.0)
				Ubercharge = 0.0;
			SetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel", Ubercharge);
		}
		//Spy Cloak ----------------------------------------------------
		if(TF2_GetPlayerClass(victim) == TFClass_Spy)
		{
			new Float:Cloak = GetEntPropFloat(victim, Prop_Send, "m_flCloakMeter");
			if(DrainAmmo_Cloak[weapon] > 1.0)
				Cloak -= DrainAmmo_Cloak[weapon] * damageMultiplier;
			else
				Cloak *= DrainAmmo_Cloak[weapon] * damageMultiplier;
			
			if(Cloak < 0.0)
				Cloak = 0.0;
			SetEntPropFloat(victim, Prop_Send, "m_flCloakMeter", Cloak);
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	DrainAmmo[ent] = false;
	DrainAmmo_Primary[ent] = 0.0;
	DrainAmmo_Secondary[ent] = 0.0;
	DrainAmmo_Metal[ent] = 0.0;
	DrainAmmo_Cloak[ent] = 0.0;
	DrainAmmo_Ubercharge[ent] = 0.0;
	DrainAmmo_Rage[ent] = 0.0;
}

stock GetClientMetal(client) // Thx Nergal.
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}
stock SetClientMetal(client, NewMetal) // Thx Nergal.
{
    if (NewMetal < 0) NewMetal = 0;
    if (NewMetal > 200) NewMetal = 200;
    SetEntProp(client, Prop_Data, "m_iAmmo", NewMetal, 4, 3);
}