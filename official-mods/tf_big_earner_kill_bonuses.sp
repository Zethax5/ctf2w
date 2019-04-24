#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <tf2>
#include <weaponmod_utils>

#define TF_ECON_DEFINDEX_BIG_EARNER 461

public void OnPluginStart() {
	HookEvent("player_death", OnPlayerDeath);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	
	if (attacker && victim
			&& WMUtil_IsWeaponEquipped(attacker, 2, TF_ECON_DEFINDEX_BIG_EARNER)) {
		GrantBigEarnerBuff(attacker, 2.0, 25.0);
	}
	else if (assister && victim
			&& WMUtil_IsWeaponEquipped(assister, 2, TF_ECON_DEFINDEX_BIG_EARNER)) {
		GrantBigEarnerBuff(assister, 1.0, 12.5);	
	}
}

static void GrantBigEarnerBuff(int client, float duration, float cloak) {
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, duration);
	
	// TODO determine if this should also be applied on big earner kills
	float flCloakMeter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", flCloakMeter + cloak);
}
