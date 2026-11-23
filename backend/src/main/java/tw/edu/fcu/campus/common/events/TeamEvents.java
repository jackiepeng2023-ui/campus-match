package tw.edu.fcu.campus.common.events;

/**
 * 隊伍流程發生的事（《軟體工程架構 3.1》第 6.4 節）。
 * 由 cases、review 在自己的資料庫交易內發布；chat 在同一筆交易內接手，寫系統訊息、調整對話成員。
 * 所以不會出現「申請成立了卻沒有對話」。推送給線上使用者則等交易提交之後。
 * actorId：做這件事的人（系統排程觸發時為空）；他自己不需要被標成未讀。
 */
public final class TeamEvents {
    private TeamEvents() {}

    /** 開隊：隊伍開始招募 */
    public record TeamOpened(int caseId, int ownerId, String title) {}

    /** 送出申請（APPLY）或邀請（INVITE）；message 是送出時附的一句話 */
    public record EngagementCreated(int engagementId, int caseId, int joinerId, int ownerId, String direction, String message, String title) {}

    /** 對方同意：joinerId 成為隊友 */
    public record EngagementAccepted(int engagementId, int caseId, int joinerId, int ownerId, String direction, Integer actorId, String title) {}

    /** 申請或邀請結束但沒有成立。reason：DECLINED 婉拒、WITHDRAWN 取消、EXPIRED 逾時、FULL 名額已滿或隊伍已成隊、TEAM_ENDED 隊伍解散或截止 */
    public record EngagementClosed(int engagementId, int caseId, int joinerId, int ownerId, String direction, String reason, Integer actorId, String title) {}

    /** 成隊。early：隊長提前成隊（名額還沒滿）；byDeadline：報名截止時以目前名單成隊 */
    public record TeamFormed(int caseId, String title, boolean early, boolean byDeadline, Integer actorId) {}

    /** 成員退出，或被隊長請離（removed）。reopened：隊伍因此回到招募中 */
    public record MemberLeft(int caseId, int userId, boolean removed, boolean reopened, String title) {}

    /** 隊長標記已報名（marked = true，名單鎖定），或取消標記 */
    public record RegistrationMarked(int caseId, int byUserId, boolean marked, String title) {}

    /** 報名截止前 7、3、1 天的提醒 */
    public record RegistrationReminder(int caseId, int daysLeft, String title) {}

    /** 隊伍結束。status：CANCELLED 解散、EXPIRED 截止未成隊、CLOSED 比賽結束 */
    public record TeamEnded(int caseId, String status, String title) {}
}
