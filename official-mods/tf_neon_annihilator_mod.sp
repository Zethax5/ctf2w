#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <tf2_stocks>

#include <sdkhooks>
#include <weaponmod_utils>

#define TF_ECON_DEFINDEX_NEON_ANNIHILATOR 813
#define TF_ECON_DEFINDEX_NEON_ANNIHILATOR_GENUINE 834

#define SCUBA_NOISE "player/breathe1.wav"

public void OnPluginStart() {
	HookEvent("post_inventory_application", OnInventoryApplied);
}

public void OnMapStart() {
	PrecacheSound(SCUBA_NOISE);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			SDKHook(i, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
}

public void OnInventoryApplied(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage,
		int &damagetype) {
	if (damagetype & DMG_DROWN) {
		int weapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)
				&& TF2_GetItemDefinitionIndex(weapon) == TF_ECON_DEFINDEX_NEON_ANNIHILATOR
					|| TF2_GetItemDefinitionIndex(weapon) == TF_ECON_DEFINDEX_NEON_ANNIHILATOR_GENUINE) {
			// Manipulate recovered amount to prevent free heals
			int iDrownRestored = GetEntProp(victim, Prop_Data, "m_idrownrestored");
			SetEntProp(victim, Prop_Data, "m_idrownrestored",
					iDrownRestored + RoundFloat(damage));
			
			EmitSoundToClient(victim, SCUBA_NOISE, victim, SNDCHAN_VOICE);
			
			damagetype &= ~DMG_DROWN;
			damage = 0.0;
			return Plugin_Changed;
		}
	} else if (damagetype & DMG_CLUB && !(damagetype & DMG_CRIT)
			&& TF2_IsPlayerInNeonCritCondition(victim)) {
		int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(weapon)
				&& TF2_GetItemDefinitionIndex(weapon) == TF_ECON_DEFINDEX_NEON_ANNIHILATOR
					|| TF2_GetItemDefinitionIndex(weapon) == TF_ECON_DEFINDEX_NEON_ANNIHILATOR_GENUINE) {
			damagetype |= DMG_CRIT;
			damage *= 3.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

static bool TF2_IsPlayerInNeonCritCondition(int client) {
	return TF2_IsPlayerInCondition(client, view_as<TFCond>(123)) // gas
			|| TF2_IsPlayerInCondition(client, TFCond_Bleeding);
}
