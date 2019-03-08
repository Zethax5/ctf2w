/*

Created by: Zethax
Document created on: January 17th, 2019
Last edit made on: January 22nd, 2019
Current version: v0.9

Attributes in this pack:
  - "ubercharge is booster shot"
      1) How much uber to drain per usage
      2) The amount of overheal the patient gains on uber
      3) How long the shield granted by ubercharge lasts in seconds
      4) The protection granted by the shield from ubercharge, from 0.0 to 1.0
      
      Ubercharge consumes X amount to grant the patient an instant overheal + a shield that lasts for
      Y seconds and grants them Z amount of protection. 

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

#define PLUGIN_NAME "tf_custom_booster_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in a custom ubercharge"
#define PLUGIN_VERS "v0.0"

#define PARTICLE_SHIELD "powerup_icon_resist"
#define SOUND_BOOSTERUBER "weapons/fx/rics/arrow_impact_crossbow_heal.wav"

public Plugin:my_info = {
	
	name	    = PLUGIN_NAME,
	author	    = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version	    = PLUGIN_VERS,
	url	    = ""
};

public OnPluginStart() {
 
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnTouchResupply);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;

		OnClientPutInServer(i);
	}
}

public OnMapStart() {
	
	PrecacheSound(SOUND_BOOSTERUBER, true);
	PrecacheParticle(PARTICLE_SHIELD);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:BoosterUber[2049];
new Float:BoosterUber_Drain[2049];
new Float:BoosterUber_Overheal[2049];
new Float:BoosterUber_ShieldDur[2049];
new Float:BoosterUber_Dur[MAXPLAYERS + 1];
new Float:BoosterUber_Protection[2049];
new BoosterUber_Particle[MAXPLAYERS + 1];
new bool:Shielded[MAXPLAYERS + 1];
new Float:BoosterUber_OldDecay[2049];
new Float:BoosterUber_UseDelay[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
		return Plugin_Continue;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return Plugin_Continue;
	
	if(StrEqual(attrib, "ubercharge is booster shot"))
	{
		new String:values[5][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		BoosterUber_Drain[weapon] = StringToFloat(values[0]);
		BoosterUber_Overheal[weapon] = StringToFloat(values[1]);
		BoosterUber_ShieldDur[weapon] = StringToFloat(values[2]);
		BoosterUber_Protection[weapon] = StringToFloat(values[3]);
		BoosterUber_OldDecay[weapon] = StringToFloat(values[4]);
		
		//sets ubercharge to an invalid value
		//making it so it doesn't do anything
		TF2Attrib_SetByName(weapon, "medigun charge is crit boost", -1.0);
		
		BoosterUber[weapon] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
		
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		BoosterUber_PreThink(client, weapon);
}

static void BoosterUber_PreThink(client, weapon)
{
	new buttons = GetClientButtons(client);
	
	if(GetEngineTime() > BoosterUber_Dur[client] + BoosterUber_ShieldDur[client] && Shielded[client])
	{
		CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[client]);
		BoosterUber_Dur[client] = 0.0;
		BoosterUber_ShieldDur[client] = 0.0;
		BoosterUber_Protection[client] = 0.0;
		BoosterUber_Particle[client] = 0;
		Shielded[client] = false;
	}
	
	if(!BoosterUber[weapon])
		return;
	
	TF2Attrib_SetByName(weapon, "overheal decay bonus", BoosterUber_OldDecay[weapon]);
	
	new Float:ubercharge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
	
	if((buttons & IN_ATTACK2) == IN_ATTACK2 && GetEngineTime() >= BoosterUber_UseDelay[weapon] + 0.25)
	{
		if(ubercharge >= BoosterUber_Drain[weapon])
		{
			if(IsValidClient(GetMediGunPatient(client)) && !Shielded[GetMediGunPatient(client)])
			{
				new patient = GetMediGunPatient(client);
				new maxhealth = GetClientMaxHealth(patient);
				
				//patient effects
				SetEntityHealth(patient, RoundFloat(maxhealth * BoosterUber_Overheal[weapon]));
				if(TF2_GetPlayerClass(patient) == TFClass_Heavy)
					SetEntityHealth(patient, maxhealth);
				BoosterUber_Dur[patient] = GetEngineTime();
				BoosterUber_ShieldDur[patient] = BoosterUber_ShieldDur[weapon];
				BoosterUber_Protection[patient] = BoosterUber_Protection[weapon];
				Shielded[patient] = true;
				TF2Attrib_SetByName(weapon, "overheal decay bonus", BoosterUber_OldDecay[weapon] * 2.0);
				
				//medic effects
				SetEntityHealth(client, RoundFloat(GetClientMaxHealth(client) * 1.5));
				
				new Float:pos[3];
				pos[2] += 100.0;
				BoosterUber_Particle[patient] = AttachParticle(patient, PARTICLE_SHIELD, BoosterUber_ShieldDur[weapon], pos);
				EmitSoundToAll(SOUND_BOOSTERUBER, patient);
				
				ubercharge -= BoosterUber_Drain[weapon];
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge);
			}
		}
		BoosterUber_UseDelay[weapon] = GetEngineTime();
	}
	if(ubercharge > 0.99)
	{
		ubercharge = 0.99;
		SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge);
	}
	
	LastTick[client] = GetEngineTime();
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker && victim)
	{
		if(Shielded[victim])
		{
			damage *= 1.0 - BoosterUber_Protection[victim];
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public void OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker && Victim)
	{
		if(Shielded[Victim])
		{
			CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[Victim]);
			BoosterUber_Dur[Victim] = 0.0;
			BoosterUber_ShieldDur[Victim] = 0.0;
			BoosterUber_Protection[Victim] = 0.0;
			BoosterUber_Particle[Victim] = 0;
			Shielded[Victim] = false;
		}
	}
}

public Action:OnTouchResupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client) && Shielded[client])
	{
		CreateTimer(0.0, RemoveParticle, BoosterUber_Particle[client]);
		BoosterUber_Dur[client] = 0.0;
		BoosterUber_ShieldDur[client] = 0.0;
		BoosterUber_Protection[client] = 0.0;
		BoosterUber_Particle[client] = 0;
		Shielded[client] = false;
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	BoosterUber[ent] = false;
	BoosterUber_Drain[ent] = 0.0;
	BoosterUber_Overheal[ent] = 0.0;
	BoosterUber_ShieldDur[ent] = 0.0;
	BoosterUber_Protection[ent] = 0.0;
}
