/*

Previous version was horribly inefficient for the server.
Ate CPU resources like woah.
Gonna rewrite it to be nicer to the server.

Created by: Zethax
Document created on: March 21st, 2019
Last edit made on: March 22nd, 2019
Current version: v1.0

Attributes in this pack:
	-> "damage charges uber"
		1) Multiplier for Medic damage to be converted to ubercharge
		2) Multiplier for patient damage to be converted to ubercharge
		3) Maximum reduction multiplier for continuous damage
		Continuous damage includes but isn't limited to Heavy's Minigun, Pyro's Flamethrower, Medic's Syringe Gun...

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_damage_charges_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which allows damage to charge Medigun Ubercharge."
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
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:DmgChargeUber[2049];
new Float:DmgChargeUber_Medic[2049];
new Float:DmgChargeUber_Patient[2049];
new Float:DmgChargeUber_Reduction[2049];
new Float:DmgChargesUber_DmgTicks[2049];
new Float:DmgChargesUber_DmgTickDelay[2049];

new Float:DmgDealt[MAXPLAYERS + 1];
new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "damage charges uber"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		DmgChargeUber_Medic[weapon] = StringToFloat(values[0]);
		DmgChargeUber_Patient[weapon] = StringToFloat(values[1]);
		DmgChargeUber_Reduction[weapon] = StringToFloat(values[2]);
		
		DmgChargeUber[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnTakeDamageAlive(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damageCustom)
{
	if(IsValidClient(attacker))
	{
		//The way the original system dealt with charging the medigun based on patient damage
		//required indexing all players and checking for which one was healing the attacker.
		//This isn't inherently bad with burst damage weapons, since it only triggers maybe twice a second.
		//But constant damage weapons were stressful on the server.
		//So, instead we'll be storing damage the attacker has dealt for use later.
		DmgDealt[attacker] += damage;
		
		new secondary = GetPlayerWeaponSlot(attacker, 1);
		if(secondary > -1 && DmgChargeUber[secondary])
		{
			new Float:ubercharge = GetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel");
			new Float:charge = damage * DmgChargeUber_Medic[secondary] / 100.0;
			new Float:reduction = 1.0 - (DmgChargeUber_Reduction[secondary] * DmgChargesUber_DmgTicks[secondary]);
			charge *= reduction;
			ubercharge += charge;
			if(ubercharge > 1.0)
				ubercharge = 1.0;
			if(ubercharge < 0.0)
				ubercharge = 0.0;
			SetEntPropFloat(secondary, Prop_Send, "m_flChargeLevel", ubercharge);
			DmgChargesUber_DmgTicks[secondary] += 0.1;
			DmgChargesUber_DmgTickDelay[secondary] = GetEngineTime();
		}
	}
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		DmgChargesUber_PreThink(client, weapon);
		LastTick[client] = GetEngineTime();
	}
}

void DmgChargesUber_PreThink(client, weapon)
{
	if(DmgChargesUber[weapon])
	{
		new patient = GetMediGunPatient(client);
		if(IsValidClient(patient) && DmgDealt[patient] > 0.0)
		{
			new Float:damage = DmgDealt[patient];
			new Float:ubercharge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
			new Float:addCharge = damage * DmgChargesUber_Patient[weapon] / 100.0;
			new Float:reduction = 1.0 - (DmgChargesUber_Reduction[weapon] * DmgChargesUber_DmgTicks[weapon]);
			addCharge *= reduction;
			ubercharge += addCharge;
			if(ubercharge > 1.0)
				ubercharge = 1.0;
			if(ubercharge < 0.0)
				ubercharge = 0.0;
			SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge);
		}
		
		if(GetEngineTime() >= DmgChargesUber_DmgTickDelay[weapon] + 0.5)
			DmgChargesUber_DmgTicks[weapon] = 0.0;
	}
	
	DmgDealt[client] = 0.0;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	DmgChargeUber[ent] = false;
	DmgChargeUber_Medic[ent] = 0.0;
	DmgChargeUber_Patient[ent] = 0.0;
	DmgChargeUber_Reduction[ent] = 0.0;
}
