package tw.edu.fcu.campus.agent;

import tw.edu.fcu.campus.ranking.RankingEngine;

/** 三個媒合 Agent 共用的資料形狀：學生技能、競賽需求、教師專長都參照同一套 Skill ID */
public final class AgentModels {
    private AgentModels() {}

    /** 需求技能：minTier 1 初階／2 中階／3 進階；core＝核心技能（權重 2），否則為輔助技能（權重 1） */
    public record Need(int skillId, String name, int minTier, int minScore, boolean core) {
        public double weight() { return core ? 2 : 1; }
        public String importance() { return core ? "CORE" : "SUPPORT"; }
    }

    /** API 輸入：importance＝CORE／SUPPORT（預設 CORE），minLevel 預設 2（中階） */
    public record NeedIn(Integer skillId, Integer minLevel, String importance) {}

    /** 給人看、也可以交給語言模型的技能描述：只有階級與可信狀態，沒有分數（D16） */
    public record SkillItem(int skillId, String name, boolean core, String required, String mine, String trust) {
        public String label() { return name + (mine == null ? "" : "（" + mine + (trust == null ? "" : "・" + trust) + "）"); }
    }

    public static String tier(int t) { return RankingEngine.tierName(t); }
    public static double round1(double v) { return Math.round(v * 10) / 10.0; }
    public static double round3(double v) { return Math.round(v * 1000) / 1000.0; }
}
