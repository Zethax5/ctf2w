/*

Created by: Zethax
Document created on: March 22nd, 2019
Last edit made on: March 22nd, 2019
Current version: v1.0

Attributes in this pack:
	-> "ubercharge meter resists damage"
		1) % of damage to reroute to ubercharge

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_uber_resists_dmg"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which redirects damage onto medigun ubercharge."
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

new bool:UberResistsDmg[2049];
new Float:UberResistsDmg_Resistance[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "ubercharge meter resists damage"))
	{
		UberResistsDmg_Resistance[weapon] = StringToFloat(value);
		UberResistsDmg[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Action:action;
	
	if(IsValidClient(victim))
	{
		new wep = GetActiveWeapon(victim);
		if(wep > -1 && UberResistsDmg[wep] && (damagetype & DMG_CRIT) != DMG_CRIT)
		{
			new Float:ubercharge = GetEntPropFloat(wep, Prop_Send, "m_flChargeLevel");
			if(ubercharge > 0.0)
			{
				new Float:removeCharge = (damage * UberResistsDmg_Resistance[wep]) / 100.0;
				damage *= 1.0 - UberResistsDmg_Resistance[wep];
				ubercharge -= removeCharge;
				if(ubercharge > 0.0)
					ubercharge = 0.0;
				SetEntPropFloat(wep, Prop_Send, "m_flChargeLevel", ubercharge);
				action = Plugin_Changed;
			}
		}
	}
	
	return action;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	UberResistsDmg[ent] = false;
	UberResistsDmg_Resistance[ent] = 0.0;
}
