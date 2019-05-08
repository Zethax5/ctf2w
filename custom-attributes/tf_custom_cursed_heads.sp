/*

Created by: Zethax
Document created on: March 21st, 2019
Last edit made on: March 22nd, 2019
Current version: v1.0

Attributes in this pack:
	-> "merasmus cursed my heads"
		1) Maximum number of heads that can be accumulated
		2) How long penalties last after using a head
		3) Health threshold to trigger using a head. Defaults to 20% of max health, so can be left empty.
		Penalties after using a head include mark for death and inability to gain or use another head temporarily.
		Can save the Demoman from fatal damage.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_cursed_heads"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute associated with gathering heads that act as resurrections"
#define PLUGIN_VERS "v1.0"

#define SOUND_USEHEAD "player/souls_receive1.wav"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEvent("player_death", OnPlayerDeath);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_USEHEAD, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:CursedHeads[2049];
new Float:CursedHeads_Duration[2049];
new CursedHeads_Heads[2049];
new CursedHeads_MaxHeads[2049];
new Float:CursedHeads_Tick[2049];
new Float:CursedHeads_Threshold[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "merasmus cursed my heads"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		CursedHeads_MaxHeads[weapon] = StringToInt(values[0]);
		CursedHeads_Duration[weapon] = StringToFloat(values[1]);
		CursedHeads_Threshold[weapon] = 0.2;
		if(strlen(values[2]))
			CursedHeads_Threshold[weapon] = StringToFloat(values[2]);
		
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		CursedHeads[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Action:action;
	if(IsValidClient(victim))
	{
		new wep = GetPlayerWeaponSlot(victim, 2);
		new health = GetClientHealth(victim);
		new threshold = RoundToCeil(GetClientMaxHealth(victim) * CursedHeads_Threshold[wep]);
		if(wep > -1 && CursedHeads_Heads[wep] > 0 && health - RoundToCeil(damage) <= threshold)
		{
			if(GetEngineTime() >= CursedHeads_Tick[wep] + CursedHeads_Duration[wep])
			{
				//Uses up one head, and prevents players from gathering or using more heads temporarily
				CursedHeads_Heads[wep]--;
				CursedHeads_Tick[wep] = GetEngineTime();
				
				//Marks player for death
				//Using a timer here to prevent damage from becoming a minicrit
				CreateTimer(0.0, MarkPlayerForDeath, victim, TIMER_FLAG_NO_MAPCHANGE);
				EmitSoundToAll(SOUND_USEHEAD, victim);
				
				SetEntProp(wep, Prop_Send, "m_iClip1", CursedHeads_Heads[wep]);
				
				//Curb damage to prevent the player from dying
				damage = float(health) - 2.0;
				//Restores player health to 50%
				SetEntityHealth(victim, RoundFloat(GetClientMaxHealth(victim) + damage));
				action = Plugin_Changed;
			}
		}
	}
	if(IsValidClient(attacker))
		LastWeaponHurtWith[attacker] = weapon;
	
	return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker))
	{
		new weapon = LastWeaponHurtWith[attacker];
		if(weapon > -1 && CursedHeads[weapon])
		{
			if(GetEngineTime() >= CursedHeads_Tick[weapon] + CursedHeads_Duration[weapon])
			{
				CursedHeads_Heads[weapon]++;
				if(CursedHeads_Heads[weapon] > CursedHeads_MaxHeads[weapon])
					CursedHeads_Heads[weapon] = CursedHeads_MaxHeads[weapon];
				
				SetEntProp(weapon, Prop_Send, "m_iClip1", CursedHeads_Heads[weapon]);
			}
		}
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	CursedHeads[ent] = false;
	CursedHeads_MaxHeads[ent] = 0;
	CursedHeads_Heads[ent] = 0;
	CursedHeads_Duration[ent] = 0.0;
	CursedHeads_Tick[ent] = 0.0;
	CursedHeads_Threshold[ent] = 0.0;
}

public Action:MarkPlayerForDeath(Handle:timer, any:client)
{
	new wep = GetPlayerWeaponSlot(client, 2);
	if(wep > -1 && CursedHeads[wep])
		TF2_AddCondition(client, TFCond_MarkedForDeath, CursedHeads_Duration[wep]);
}
