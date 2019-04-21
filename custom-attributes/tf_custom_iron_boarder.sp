/*

Created by: Zethax
Document created on: March 10th, 2019
Last edit made on: March 11th, 2019
Current version: v1.0

Attributes in this pack:
	-> "iron boarder attribute"
		1) Maximum healing on hit without a shield equipped
		2) Maximum shield charge on hit with a shield equipped
		
	-> "damage bonus while shield is recharging"
		1) Damage bonus to grant while your shield is recharging
	
	-> "reload speed penalty in non shield mode"
		1) Reload speed penalty to apply with no shield equipped

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_iron_boarder"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in attributes associated with a very unique Grenade Launcher"
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
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:IronBoarder[2049];
new Float:IronBoarder_HealOnHit[2049];
new Float:IronBoarder_ShieldOnHit[2049];
new bool:IronBoarder_ShieldMode[2049];

new bool:ShieldRechargeDmgBonus[2049];
new Float:ShieldRechargeDmgBonus_Mult[2049];

new Float:ReloadSpeedPenalty[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "iron boarder attribute"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		IronBoarder_HealOnHit[weapon] = StringToFloat(values[0]);
		IronBoarder_ShieldOnHit[weapon] = StringToFloat(values[1]);
		
		//for detecting shield and putting the weapon into shield mode if one is detected
		CreateTimer(0.0, DetectShieldMode, weapon, TIMER_FLAG_NO_MAPCHANGE);
		
		IronBoarder[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "damage bonus while shield is recharging"))
	{
		ShieldRechargeDmgBonus_Mult[weapon] = StringToFloat(value);
		
		ShieldRechargeDmgBonus[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "reload speed penalty in non shield mode"))
	{
		ReloadSpeedPenalty[weapon] = StringToFloat(value);
		CreateTimer(0.3, ApplyReloadPenalty, weapon, TIMER_FLAG_NO_MAPCHANGE);
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:DetectShieldMode(Handle:timer, any:weapon)
{
	new owner = ReturnOwner(weapon);
	if(owner > -1)
	{
		new secondary = GetPlayerWeaponSlot(owner, 1);
		if(secondary > -1) //if the weapon isn't a shield
		{
			IronBoarder_ShieldMode[weapon] = false; //tell system not to restore shield on hit
			TF2Attrib_SetByName(weapon, "health on radius damage", IronBoarder_HealOnHit[weapon]); //weapon will restore health on hit instead of shield
		}
		else
			IronBoarder_ShieldMode[weapon] = true; //tell system to handle restoring shield on hit
	}
}

public Action:ApplyReloadPenalty(Handle:timer, any:weapon)
{
	if(!IronBoarder[weapon])
		return Plugin_Continue;
	
	if(IronBoarder_ShieldMode[weapon])
		return Plugin_Continue;
	
	TF2Attrib_SetByName(weapon, "reload time increased hidden", 1.0 + ReloadSpeedPenalty[weapon]);
	ReloadSpeedPenalty[weapon] = 0.0;
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker && weapon > -1)
	{
		if(IronBoarder[weapon] && IronBoarder_ShieldMode[weapon])
		{
			new Float:m_flChargeMeter = GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
			m_flChargeMeter += IronBoarder_ShieldOnHit[weapon] / 2;
			
			if(m_flChargeMeter > 100.0) //prevents overcharge
				m_flChargeMeter = 100.0;
			if(m_flChargeMeter < 0.0) //prevents undercharge
				m_flChargeMeter = 0.0;
				
			SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", m_flChargeMeter);
		}
		if(ShieldRechargeDmgBonus[weapon] && GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter") < 100.0)
		{
			damage *= 1.0 + ShieldRechargeDmgBonus_Mult[weapon];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	IronBoarder[ent] = false;
	IronBoarder_HealOnHit[ent] = 0.0;
	IronBoarder_ShieldOnHit[ent] = 0.0;
	IronBoarder_ShieldMode[ent] = false;
	
	ShieldRechargeDmgBonus[ent] = false;
	ShieldRechargeDmgBonus_Mult[ent] = 0.0;
}
