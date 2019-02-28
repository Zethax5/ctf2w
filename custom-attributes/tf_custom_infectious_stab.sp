/*

This one is quite loaded. Lots to check for
There's death checks, damage checks, thinking,
even inventory application and medkit checks.

Created by: Zethax
Document created on: February 26th, 2019
Last edit made on: February 28th, 2019
Current version: v1.0

Attributes in this pack:
	- "backstab is infectious"
		1) Duration of the infection
		2) Radial infection radius
		3) Whether or not the infection makes victims take minicrit damage
		
		On backstab, player will infect the victim and all nearby enemies with a deadly plague.
		This plague will last for X seconds on the victim, and half that on nearby enemies.
		Players will take damage per second based on max health and duration of the plague.
		The plague can be shortened or removed by medics & dispensers, and removed by
		stepping into a respawn room or picking up a medkit.
		
		Razorback snipers are infected for half the duration.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_infectious_stab"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that converts the Spy's backstab to an infection."
#define PLUGIN_VERS "v1.0"

#define SOUND_PLAGUE_LOOP "items/powerup_pickup_plague_infected_loop.wav"
#define SOUND_PLAGUE_INFECTED "items/powerup_pickup_plague_infected.wav"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
	
	HookEvent("player_death", OnPlayerDeath);
	HookEntityOutput("item_healthkit_small", "OnPlayerTouch", OnTouchHealthKit);
	HookEntityOutput("item_healthkit_medium", "OnPlayerTouch", OnTouchHealthKit);
	HookEntityOutput("item_healthkit_full", "OnPlayerTouch", OnTouchHealthKit);
	
	new iSpawn = -1;
	while ((iSpawn = FindEntityByClassname(iSpawn, "func_respawnroom")) != -1)
	{
		SDKHook(iSpawn, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(iSpawn, SDKHook_EndTouch, SpawnEndTouch);
	}
 
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_PLAGUE_INFECTED, true);
	PrecacheSound(SOUND_PLAGUE_LOOP, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_Think, OnClientThink);
}

new bool:PoisonStab[2049];
new Float:PoisonStab_Duration[2049];
new Float:PoisonStab_Radius[2049];
new bool:PoisonStab_MFD[2049];

new bool:Infected[MAXPLAYERS + 1];
new InfectorID[MAXPLAYERS + 1];
new Float:Infected_Dur[MAXPLAYERS + 1];
new Float:Infected_DmgDelay[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];
new bool:IsInSpawn[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
		
	if(StrEqual(attrib, "backstab is infectious"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		PoisonStab_Duration[weapon] = StringToFloat(values[0]);
		PoisonStab_Radius[weapon] = StringToFloat(values[1]);
		if(strlen(values[2]) && StringToInt(values[2]) > 0)
			PoisonStab_MFD[weapon] = true;
		
		PoisonStab[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker)
	{
		if(PoisonStab[weapon] && damageCustom == TF_CUSTOM_BACKSTAB)
		{
			PoisonStab_OnTakeDamage(attacker, victim, weapon);
			
			//makes it so the backstab doesn't instakill
			damage = 3.3334;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

//used for reseting infection on death
//so infection doesn't carry over if they die
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim)
	{
		if(Infected[victim])
		{
			Infected[victim] = false;
			InfectorID[victim] = -1;
			Infected_Dur[victim] = 0.0;
			Infected_DmgDelay[victim] = 0.0;
			PoisonStab_Duration[victim] = 0.0;
			StopSound(victim, SNDCHAN_AUTO, SOUND_PLAGUE_LOOP);
		}
	}
}

public OnTouchHealthKit(const String:output[], caller, client, Float:delay)
{
	if(Infected[client])
	{
		Infected[client] = false;
		InfectorID[client] = -1;
		Infected_Dur[client] = 0.0;
		Infected_DmgDelay[client] = 0.0;
		PoisonStab_Duration[client] = 0.0;
		TF2_RemoveCondition(client, TFCond_MarkedForDeath);
		StopSound(client, SNDCHAN_AUTO, SOUND_PLAGUE_LOOP);
	}
}

public SpawnStartTouch(spawn, client)
{
	if(!IsValidClient(client))
		return;
	
	IsInSpawn[client] = true;
}
public SpawnEndTouch(spawn, client)
{
	if(!IsValidClient(client))
		return;
	
	IsInSpawn[client] = false;
}

public OnClientThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(Infected[client] && GetEngineTime() >= LastTick[client] + 0.1)
		Infected_OnThink(client);
	
}

void PoisonStab_OnTakeDamage(attacker, victim, weapon)
{
	//infects the backstab victim
	//and initializes values on the victim specifically for dealing damage
	Infected[victim] = true;
	InfectorID[victim] = attacker;
	Infected_Dur[victim] = GetEngineTime();
	PoisonStab_Duration[victim] = PoisonStab_Duration[weapon];
	if(PoisonStab_MFD[weapon])
		TF2_AddCondition(victim, TFCond_MarkedForDeath, PoisonStab_Duration[weapon]);
	
	//plays sounds to victim and attacker
	EmitSoundToClient(attacker, SOUND_PLAGUE_INFECTED);
	EmitSoundToClient(victim, SOUND_PLAGUE_INFECTED);
	EmitSoundToClient(victim, SOUND_PLAGUE_LOOP);
	
	new Float:attackerPos[3];
	GetClientAbsOrigin(attacker, attackerPos);
	new Float:targetPos[3];
	
	//indexes all players on the server and checks for distance from the spy
	//really inefficient, so we only do this once and only on backstab
	for (new target = 1; target < MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(attacker) && target != victim)
		{
			GetClientAbsOrigin(target, targetPos);
			if(GetVectorDistance(attackerPos, targetPos) >= PoisonStab_Radius[weapon])
			{
				Infected[target] = true;
				InfectorID[target] = attacker;
				Infected_Dur[target] = GetEngineTime();
				PoisonStab_Duration[target] = PoisonStab_Duration[weapon] / 2;
				if(PoisonStab_MFD[weapon])
					TF2_AddCondition(target, TFCond_MarkedForDeath, PoisonStab_Duration[weapon] / 2);
				
				EmitSoundToClient(attacker, SOUND_PLAGUE_INFECTED);
				EmitSoundToClient(target, SOUND_PLAGUE_INFECTED);
				EmitSoundToClient(target, SOUND_PLAGUE_LOOP);
			}
		}
	}
}

void Infected_OnThink(client)
{
	if(Infected[client] && GetEngineTime() >= Infected_DmgDelay[client] + 0.5)
	{
		new damage = RoundFloat(GetClientMaxHealth(client) / (PoisonStab_Duration[client] / 2));
		DealDamage(client, damage, InfectorID[client], DMG_POISON);
		Infected_DmgDelay[client] = GetEngineTime();
	}
	if(GetEntProp(client, Prop_Send, "m_nNumHealers") > 0)
	{
		new healers = GetEntProp(client, Prop_Send, "m_nNumHealers");
		Infected_Dur[client] -= 0.1 * healers;
	}
	if(GetEngineTime() >= Infected_Dur[client] + PoisonStab_Duration[client] || IsInSpawn[client])
	{
		Infected[client] = false;
		Infected_Dur[client] = 0.0;
		PoisonStab_Duration[client] = 0.0;
		InfectorID[client] = -1;
		TF2_RemoveCondition(client, TFCond_MarkedForDeath);
		StopSound(client, SNDCHAN_AUTO, SOUND_PLAGUE_LOOP);
	}
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	PoisonStab[ent] = false;
	PoisonStab_Duration[ent] = 0.0;
	PoisonStab_Radius[ent] = 0.0;
	PoisonStab_MFD[ent] = false;
}
