/*
Created by: Zethax
Document created on: April 2019
Last edit made on: April 23rd, 2019
Current version: v1.0
Attributes in this pack:
	-> "earthquake on blast jump land"
		1) Range
		2) Maximum damage
		3) Distance falloff multiplier
		4) Knockback multiplier
		Creates earthquakes when the player lands from a blast jump
		
	-> "earthquake on fall damage"
		Same values as "earthquake on blast jump land"
		Will create an earthquake when the player takes fall damage instead of when the player lands from a blast jump.
*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <smlib>

#define PLUGIN_NAME "tf_custom_earthquake"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in 2 attributes associated with creating earthquakes."
#define PLUGIN_VERS "v1.0"

#define TEAM_RED    2
#define TEAM_BLUE   3
#define SOUND_EXPLOSION_BIG                 "ambient/explosions/explode_8.wav"

// Attribute Stuff
#define ATTRIBUTE_1026_PUSHSCALE                    0.03
#define ATTRIBUTE_1026_PUSHMAX                      3.0
#define ATTRIBUTE_1026_COOLDOWN                     3.5

new g_iExplosionSprite;
new g_iHaloSprite;
new g_iWhite;
new g_iTeamColorSoft[4][4];

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEvent("rocket_jump_landed", OnBlastJumpLanded);
	HookEvent("sticky_jump_landed", OnBlastJumpLanded);
	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
	
	g_iTeamColorSoft[TEAM_RED][0] = 189;
	g_iTeamColorSoft[TEAM_RED][1] = 59;
	g_iTeamColorSoft[TEAM_RED][2] = 59;
	g_iTeamColorSoft[TEAM_RED][3] = 255;
	g_iTeamColorSoft[TEAM_BLUE][0] = 91;
	g_iTeamColorSoft[TEAM_BLUE][1] = 122;
	g_iTeamColorSoft[TEAM_BLUE][2] = 140;
	g_iTeamColorSoft[TEAM_BLUE][3] = 255;

}

public OnMapStart()
{
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	g_iWhite = PrecacheModel("materials/sprites/white.vmt");
	
	PrecacheSound(SOUND_EXPLOSION_BIG, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:Earthquake[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Damage[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Radius[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_Falloff[MAXPLAYERS + 1][MAXSLOTS + 1];
new Float:Earthquake_KnockbackMult[MAXPLAYERS + 1][MAXSLOTS + 1];
new bool:Earthquake_WhileActive[MAXPLAYERS + 1][MAXSLOTS + 1];
new bool:Earthquake_TriggerFromFallDamage[MAXPLAYERS + 1][MAXSLOTS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
		
	if(StrEqual(attrib, "earthquake on blast jump land"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		Earthquake_Radius[client][slot] = StringToFloat(values[0]);
		Earthquake_Damage[client][slot] = StringToFloat(values[1]);
		Earthquake_Falloff[client][slot] = StringToFloat(values[2]);
		Earthquake_KnockbackMult[client][slot] = StringToFloat(values[3]);
		Earthquake_WhileActive[client][slot] = whileActive;
		
		Earthquake[client][slot] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "earthquake on fall damage"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		Earthquake_Radius[client][slot] = StringToFloat(values[0]);
		Earthquake_Damage[client][slot] = StringToFloat(values[1]);
		Earthquake_Falloff[client][slot] = StringToFloat(values[2]);
		Earthquake_KnockbackMult[client][slot] = StringToFloat(values[3]);
		Earthquake_WhileActive[client][slot] = whileActive;
		
		Earthquake[client][slot] = true;
		Earthquake_TriggerFromFallDamage[client][slot] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnBlastJumpLanded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
		return Plugin_Continue;
	
	if(GetHasAttributeInAnySlot(client, _, Earthquake) && !GetHasAttributeInAnySlot(client, _, Earthquake_TriggerFromFallDamage))
	{
		new wep = GetSlotContainingAttribute(client, Earthquake);
		if(!Earthquake_WhileActive[client][wep] || (Earthquake_WhileActive[client][GetWeaponSlot(client, GetActiveWeapon(client))] && wep > -1 && wep < 2049))
		{
			CreateEarthquake(client, wep);
		}
	}
	
	return Plugin_Continue;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(damagetype & DMG_FALL)
	{
		if(IsValidClient(victim) && GetHasAttributeInAnySlot(victim, _, Earthquake_TriggerFromFallDamage))
		{
			new wep = GetSlotContainingAttribute(victim, Earthquake);
			if(!Earthquake_WhileActive[victim][wep] || (Earthquake_WhileActive[victim][GetWeaponSlot(victim, GetActiveWeapon(victim))] && wep > -1 && wep < 2049))
			{
				CreateEarthquake(victim, wep);
			}
		}
	}
	return Plugin_Continue;
}

public CW3_OnWeaponRemoved(slot, client)
{
	Earthquake[client][slot] = false;
	Earthquake_Radius[client][slot] = 0.0;
	Earthquake_Damage[client][slot] = 0.0;
	Earthquake_Falloff[client][slot] = 0.0;
	Earthquake_KnockbackMult[client][slot] = 0.0;
	Earthquake_WhileActive[client][slot] = false;
	Earthquake_TriggerFromFallDamage[client][slot] = false;
}

new Float:g_f1026LastLand[MAXPLAYERS+1] = 0.0;

stock CreateEarthquake(client, slot)
{
	if(GetEngineTime() <= g_f1026LastLand[client] + ATTRIBUTE_1026_COOLDOWN) return;
	
	if((GetHasAttributeInAnySlot(client, _, Earthquake) && !GetHasAttributeInAnySlot(client, _, Earthquake_WhileActive)) || Earthquake_WhileActive[client][slot])
	{
		new Float:range = Earthquake_Radius[client][slot];
		new Float:fPushMax = ATTRIBUTE_1026_PUSHMAX;
		
		new Float:fDistance;
		
		decl Float:vClientPos[3];
		Entity_GetAbsOrigin(client, vClientPos);
		decl Float:vVictimPos[3];
		decl Float:vPush[3];
		
		new team = GetClientTeam(client);
		
		EmitSoundFromOrigin(SOUND_EXPLOSION_BIG, vClientPos);
		TE_SetupExplosion(vClientPos, g_iExplosionSprite, 10.0, 1, 0, 0, 750);
		TE_SendToAll();
		TE_SetupBeamRingPoint(vClientPos, 10.0, range, g_iWhite, g_iHaloSprite, 0, 10, 0.2, 10.0, 0.5, g_iTeamColorSoft[team], 50, 0);
		TE_SendToAll();
		
		Shake(client);
		
		for(new victim = 0; victim <= MaxClients; victim++)
		{
			if(Client_IsValid(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && team != GetClientTeam(victim) && OnGround(victim))
			{
				Entity_GetAbsOrigin(victim, vVictimPos);
				fDistance = GetVectorDistance(vVictimPos, vClientPos);
				if(fDistance <= range)
				{
					new Float:falloff = Earthquake_Falloff[client][slot];
					new Float:baseDamage = Earthquake_Damage[client][slot];
					SubtractVectors(vVictimPos, vClientPos, vPush);
					new Float:fPushScale = ((range - fDistance) / range)*Earthquake_KnockbackMult[client][slot];
					if(fPushScale > fPushMax) fPushScale = fPushMax;
					ScaleVector(vPush, fPushScale);
					Shake(victim);
					if(vPush[2] < 400.0) vPush[2] = 400.0;
					TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vPush);
					g_f1026LastLand[client] = GetEngineTime();
					new Float:fDamage = (baseDamage * falloff) + (baseDamage * (1.0 - falloff) * ((range - fDistance) / range); 
					Entity_Hurt(victim, RoundFloat(fDamage), client, TF_CUSTOM_BOOTS_STOMP, "tf_wearable"); 
					if(TF2_IsPlayerInCondition(victim, TFCond_Milked))
						HealOnHit(client, RoundFloat(fDamage * 0.6), 1.0);
					if(TF2_IsPlayerInCondition(client, TFCond:29))
						HealOnHit(client, RoundFloat(fDamage * 0.35), 1.0);
				}
			}
		}
	}
}

stock bool:GetHasAttributeInAnySlot(client, slot = -1, const attribute[][] = m_bHasAttribute)
{
	if(!Client_IsValid(client)) return false;
	
	for(new i = 0; i < MAXSLOTS; i++)
	{
		if(attribute[client][i])
		{
			if(slot == -1 || slot == i) return true;
		}
	}
	
	return false;
}
stock Shake(client)
{    
	new flags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
	SetCommandFlags("shake", flags);

	FakeClientCommand(client, "shake");
	
	flags = GetCommandFlags("shake") | (FCVAR_CHEAT);
	SetCommandFlags("shake", flags);
}
stock EmitSoundFromOrigin(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, orig, NULL_VECTOR, true, 0.0);
}
stock bool:OnGround(client)
{
	return (GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND);
}
stock GetSlotContainingAttribute(client, const attribute[][] = m_bHasAttribute)
{
	if(!Client_IsValid(client)) return false;
	
	for(new i = 0; i < MAXSLOTS; i++)
	{
		if(attribute[client][i])
		{
			return i;
		}
	}
	
	return -1;
}

stock HealOnHit(patient = -1, amount = 0, Float:overheal = 1.0)
{
	if (patient <= 0 || patient > MaxClients)return;
	new health = GetClientHealth(patient);
	new maxhealth = GetClientMaxHealth(patient);
	if(amount > 0)
	{
		health += amount;
		if(health > maxhealth * overheal)
		{
			health = RoundFloat(maxhealth * overheal);
		}
		new Handle:healevent = CreateEvent("player_healonhit", true);
		SetEventInt(healevent, "entindex", patient);
		SetEventInt(healevent, "amount", amount);
		FireEvent(healevent);
		SetEntityHealth(patient, health);
	}
}
