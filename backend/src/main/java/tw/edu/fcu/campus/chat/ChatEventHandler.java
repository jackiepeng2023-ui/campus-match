package tw.edu.fcu.campus.chat;

import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.events.TeamEvents.*;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * 接收隊伍流程的事件，寫系統訊息、調整對話成員、排入推送。
 * 這些處理和發布事件的那一方在同一筆資料庫交易內：流程成立，對話就一定跟著成立；任何一步失敗，整筆一起復原。
 * 系統訊息一律用白話，不出現內部代號。
 */
@Component
public class ChatEventHandler {
    private final ChatService chat;

    public ChatEventHandler(ChatService chat) { this.chat = chat; }

    private static String what(String direction) { return "INVITE".equals(direction) ? "邀請" : "申請"; }

    @EventListener @Transactional
    public void on(TeamOpened e) {
        if (chat.teamOf(e.caseId()) != null) return;
        int conv = chat.openTeam(e.caseId());
        chat.system(conv, "隊伍群組開好了。有人加入之後，大家都在這裡討論。", e.ownerId());
    }

    @EventListener @Transactional
    public void on(EngagementCreated e) {
        boolean invite = "INVITE".equals(e.direction());
        int initiator = invite ? e.ownerId() : e.joinerId();
        int conv = chat.openTalk(e.caseId(), e.engagementId(), e.joinerId(), e.ownerId());
        chat.system(conv, invite
                ? chat.name(e.ownerId()) + " 邀請 " + chat.name(e.joinerId()) + " 加入「" + e.title() + "」。可以先在這裡聊聊，再決定要不要接受。"
                : chat.name(e.joinerId()) + " 想加入「" + e.title() + "」。可以先在這裡聊聊，隊長再決定要不要接受。", initiator);
        if (e.message() != null && !e.message().isBlank()) chat.text(conv, initiator, e.message().strip());
        chat.push(List.of(e.joinerId(), e.ownerId()), "type", "engagement.updated", "engagementId", e.engagementId(), "caseId", e.caseId(),
                "conversationId", conv, "status", "PENDING");
    }

    @EventListener @Transactional
    public void on(EngagementAccepted e) {
        Integer talk = chat.talkOf(e.engagementId());
        if (talk != null) chat.system(talk, "已經是隊友了。之後的討論可以到隊伍群組。", e.actorId());
        Integer team = chat.teamOf(e.caseId());
        if (team == null) team = chat.openTeam(e.caseId());     // 2.0 留下來、還沒有群組的隊伍
        chat.join(team, e.joinerId());
        chat.system(team, chat.name(e.joinerId()) + " 加入了隊伍。", null);
        Set<Integer> to = new LinkedHashSet<>(chat.members(team)); to.add(e.ownerId());
        chat.push(to, "type", "engagement.updated", "engagementId", e.engagementId(), "caseId", e.caseId(), "conversationId", talk, "status", "ACCEPTED");
        chat.push(to, "type", "team.updated", "caseId", e.caseId(), "conversationId", team);
    }

    @EventListener @Transactional
    public void on(EngagementClosed e) {
        Integer talk = chat.talkOf(e.engagementId());
        String w = what(e.direction());
        if (talk != null) {
            chat.system(talk, switch (e.reason()) {
                case "DECLINED" -> "這筆" + w + "已婉拒。";
                case "WITHDRAWN" -> "這筆" + w + "已取消。";
                case "EXPIRED" -> "超過回覆期限，這筆" + w + "已失效。";
                case "FULL" -> "隊伍已經成隊，不再收人，這筆" + w + "已結束。";
                default -> "隊伍已停止招募，這筆" + w + "已結束。";
            }, e.actorId());
            chat.close(talk);
            chat.push(List.of(e.joinerId(), e.ownerId()), "type", "conversation.updated", "conversationId", talk, "readOnly", true);
        }
        chat.push(List.of(e.joinerId(), e.ownerId()), "type", "engagement.updated", "engagementId", e.engagementId(), "caseId", e.caseId(),
                "conversationId", talk, "status", e.reason());
    }

    @EventListener @Transactional
    public void on(TeamFormed e) {
        Integer team = chat.teamOf(e.caseId());
        if (team == null) return;
        String next = "下一步：到比賽官網完成報名，報名後由隊長回來按「已報名」。";
        chat.system(team, e.byDeadline() ? "報名截止，隊伍以目前的名單成隊。"
                : e.early() ? "隊長確認成隊，不再收新的申請。" + next : "人到齊，成隊了。" + next, e.actorId());
        chat.push(chat.members(team), "type", "team.updated", "caseId", e.caseId(), "conversationId", team, "status", "FORMED");
    }

    @EventListener @Transactional
    public void on(MemberLeft e) {
        Integer team = chat.teamOf(e.caseId());
        if (team == null) return;
        String name = chat.name(e.userId());
        chat.leave(team, e.userId());
        chat.system(team, (e.removed() ? "隊長調整了名單，" + name + " 已離開隊伍。" : name + " 退出了隊伍。") + (e.reopened() ? "隊伍回到招募中。" : ""), null);
        chat.push(List.of(e.userId()), "type", "conversation.updated", "conversationId", team, "left", true);
        chat.push(chat.members(team), "type", "team.updated", "caseId", e.caseId(), "conversationId", team);
    }

    @EventListener @Transactional
    public void on(RegistrationMarked e) {
        Integer team = chat.teamOf(e.caseId());
        if (team == null) return;
        chat.system(team, e.marked() ? "隊長已標記「已報名」，名單鎖定。比賽加油！" : "隊長取消了「已報名」的標記，名單可以再調整。", e.byUserId());
        chat.push(chat.members(team), "type", "team.updated", "caseId", e.caseId(), "conversationId", team);
    }

    @EventListener @Transactional
    public void on(RegistrationReminder e) {
        Integer team = chat.teamOf(e.caseId());
        if (team == null) return;
        chat.system(team, "距離報名截止還有 " + e.daysLeft() + " 天。還沒到比賽官網報名的話，記得處理；報名後由隊長按「已報名」。", null);
    }

    @EventListener @Transactional
    public void on(TeamEnded e) {
        Integer team = chat.teamOf(e.caseId());
        if (team == null) return;
        chat.system(team, switch (e.status()) {
            case "CANCELLED" -> "隊長解散了隊伍，這個群組改成唯讀。";
            case "EXPIRED" -> "報名截止前沒有成隊，這個群組改成唯讀。";
            default -> "比賽結束了，這個群組改成唯讀。辛苦了！";
        }, null);
        chat.close(team);
        chat.push(chat.members(team), "type", "conversation.updated", "conversationId", team, "readOnly", true);
        chat.push(chat.members(team), "type", "team.updated", "caseId", e.caseId(), "conversationId", team, "status", e.status());
    }
}
