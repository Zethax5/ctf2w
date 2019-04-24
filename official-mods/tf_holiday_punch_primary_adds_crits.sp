/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/tf/econ>
#include <stocksoup/log_server>

#define TF_ECON_DEFINDEX_HOLIDAY_PUNCH 656

#define TIME_HOLIDAY_PUNCH_INCREMENT 1.0
#define TIME_HOLIDAY_PUNCH_MAXIMUM 4.0

float g_flStoredHolidayPunchCritTime[MAXPLAYERS + 1];
float g_flHolidayPunchCritEndTime[MAXPLAYERS + 1];

public void OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnInventoryApplied);
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			HookWeaponSwitch(i);\
		}
	}
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	// TODO reset on inventory change
	g_flStoredHolidayPunchCritTime[client] = 0.0;
}

public void OnInventoryApplied(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client) {
		return;
	}
	
	int hMelee = GetPlayerWeaponSlot(client, 2);
	if (!IsValidEntity(hMelee) || !HasEntProp(hMelee, Prop_Send, "m_iItemDefinitionIndex")) {
		return;
	}
	
	if (TF2_GetItemDefinitionIndex(hMelee) != TF_ECON_DEFINDEX_HOLIDAY_PUNCH) {
		return;
	}
	
	// ammo counter shenanigans
	int nCritTime = RoundToCeil(g_flStoredHolidayPunchCritTime[client]);
	SetEntProp(hMelee, Prop_Send, "m_iClip1", nCritTime);
	SetEntProp(hMelee, Prop_Data, "m_iPrimaryAmmoType", 4);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	int weaponid = event.GetInt("weaponid");
	
	if(assister)
	{
		g_flStoredHolidayPunchCritTime[assister] += TIME_HOLIDAY_PUNCH_INCREMENT / 2.0;
		
		if (g_flStoredHolidayPunchCritTime[assister] > TIME_HOLIDAY_PUNCH_MAXIMUM) {
			g_flStoredHolidayPunchCritTime[assister] = TIME_HOLIDAY_PUNCH_MAXIMUM;
		}
		
		int melee = GetPlayerWeaponSlot(assister, 2);
		if (!IsValidEntity(melee)
				|| TF2_GetItemDefinitionIndex(melee) != TF_ECON_DEFINDEX_HOLIDAY_PUNCH) {
			g_flStoredHolidayPunchCritTime[assister] = 0.0;
		}
	}
	
	if (weaponid != TF_WEAPON_MINIGUN) {
		return;
	}
	
	int hMelee = GetPlayerWeaponSlot(attacker, 2);
	if (!IsValidEntity(hMelee)
			|| TF2_GetItemDefinitionIndex(hMelee) != TF_ECON_DEFINDEX_HOLIDAY_PUNCH) {
		g_flStoredHolidayPunchCritTime[attacker] = 0.0;
		return;
	}
	
	if (g_flStoredHolidayPunchCritTime[attacker] < 0.0) {
		g_flStoredHolidayPunchCritTime[attacker] = 0.0;
	}
	
	g_flStoredHolidayPunchCritTime[attacker] += TIME_HOLIDAY_PUNCH_INCREMENT;
	
	if (g_flStoredHolidayPunchCritTime[attacker] > TIME_HOLIDAY_PUNCH_MAXIMUM) {
		g_flStoredHolidayPunchCritTime[attacker] = TIME_HOLIDAY_PUNCH_MAXIMUM;
	}
}

public void OnClientPutInServer(int client) {
	HookWeaponSwitch(client);
}

void HookWeaponSwitch(int client) {
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnWeaponSwitchPost(int client, int weapon) {
	if (g_flStoredHolidayPunchCritTime[client] <= 0.0) {
		return;
	}
	
	SDKUnhook(client, SDKHook_PreThinkPost, OnHolidayPunchThink);
	if (IsValidEntity(weapon)
			&& TF2_GetItemDefinitionIndex(weapon) == TF_ECON_DEFINDEX_HOLIDAY_PUNCH) {
		g_flHolidayPunchCritEndTime[client] =
				GetGameTime() + g_flStoredHolidayPunchCritTime[client];
		TF2_AddCondition(client, TFCond_CritOnDamage, g_flStoredHolidayPunchCritTime[client]);
		
		SDKHook(client, SDKHook_PreThinkPost, OnHolidayPunchThink);
	} else {
		TF2_RemoveCondition(client, TFCond_CritOnDamage);
		g_flStoredHolidayPunchCritTime[client] =
				g_flHolidayPunchCritEndTime[client] - GetGameTime();
	}
}

public void OnHolidayPunchThink(int client) {
	int hMelee = GetPlayerWeaponSlot(client, 2);
	if (!IsValidEntity(hMelee)
			|| TF2_GetItemDefinitionIndex(hMelee) != TF_ECON_DEFINDEX_HOLIDAY_PUNCH) {
		return;
	}
	
	int nCritTime = RoundToCeil(g_flHolidayPunchCritEndTime[client] - GetGameTime());
	if (nCritTime >= 0) {
		SetEntProp(hMelee, Prop_Send, "m_iClip1", nCritTime);
	}
}
