-- Rounds — require Pro to give Pro
-- Safe to re-run.
--
-- The referral loop let a *free* user hand out full Rounds Pro. Anyone could
-- install the app, never pay, share their auto-generated code, and their three
-- friends each got Pro for nothing — and each of those friends then had a code
-- of their own. That is unbounded free Pro from a single install, with no
-- purchase anywhere in the chain.
--
-- The intent was always "Pro users can gift Pro to friends". This enforces it:
-- an invite code only works while its owner actually has Pro, by the same
-- definition the rest of the system uses (profile_has_pro: a redeemed code or
-- a live subscription).
--
-- Campaign and master codes are unaffected — those are issued deliberately and
-- have their own quotas.

create or replace function public.claim_code(
    p_code          text,
    p_user          uuid,
    p_max_referrals integer default 3
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_code      text := upper(trim(p_code));
    v_promo     public.promo_codes%rowtype;
    v_owner_id  uuid;
    v_source    text;
    v_campaign  uuid;
    v_duration  text;
    v_expires   timestamptz;
    v_used      integer;
begin
    if v_code is null or v_code = '' then
        return jsonb_build_object('status', 'invalid_code');
    end if;

    if exists (select 1 from public.profiles where id = p_user and pro_source <> 'none') then
        return jsonb_build_object('status', 'already_pro');
    end if;
    if exists (select 1 from public.redemptions where redeemer_id = p_user) then
        return jsonb_build_object('status', 'already_pro');
    end if;

    -- 1) Campaign / promo code. Locked so quota is enforced atomically.
    select * into v_promo from public.promo_codes where code = v_code for update;

    if found then
        if not v_promo.is_active then
            return jsonb_build_object('status', 'code_inactive');
        end if;
        if v_promo.starts_at is not null and now() < v_promo.starts_at then
            return jsonb_build_object('status', 'code_not_started');
        end if;
        if v_promo.expires_at is not null and now() > v_promo.expires_at then
            return jsonb_build_object('status', 'code_expired');
        end if;
        if v_promo.max_redemptions is not null
           and v_promo.redemption_count >= v_promo.max_redemptions then
            return jsonb_build_object('status', 'code_exhausted');
        end if;

        v_source   := case when v_promo.kind = 'master' then 'master' else 'campaign' end;
        v_campaign := v_promo.campaign_id;
        v_duration := v_promo.grant_duration;

        update public.promo_codes
           set redemption_count = redemption_count + 1
         where id = v_promo.id;

    else
        -- 2) Per-user referral code.
        select id into v_owner_id from public.profiles where referral_code = v_code;
        if v_owner_id is null then
            return jsonb_build_object('status', 'invalid_code');
        end if;
        if v_owner_id = p_user then
            return jsonb_build_object('status', 'own_code');
        end if;

        -- You cannot give away what you do not have. Checked at redemption
        -- rather than at code-generation time so that a lapsed subscriber's
        -- outstanding invites stop working, and a new subscriber's start,
        -- without any code being reissued.
        if not public.profile_has_pro(v_owner_id) then
            return jsonb_build_object('status', 'inviter_not_pro');
        end if;

        select count(*) into v_used
          from public.redemptions where code_owner_id = v_owner_id;
        if v_used >= p_max_referrals then
            return jsonb_build_object('status', 'code_exhausted');
        end if;

        v_source   := 'referral';
        v_duration := 'lifetime';
    end if;

    v_expires := public.grant_expiry(v_duration);

    insert into public.redemptions (
        code_used, redeemer_id, code_owner_id,
        promo_code_id, campaign_id, source, grant_duration, grant_expires_at
    ) values (
        v_code, p_user, v_owner_id,
        v_promo.id, v_campaign, v_source, v_duration, v_expires
    );

    return jsonb_build_object(
        'status',         'claimed',
        'source',         v_source,
        'campaign_id',    v_campaign,
        'promo_code_id',  v_promo.id,
        'owner_id',       v_owner_id,
        'grant_duration', v_duration,
        'expires_at',     v_expires
    );
exception
    when unique_violation then
        return jsonb_build_object('status', 'already_pro');
end;
$$;

revoke all on function public.claim_code(text, uuid, integer) from public, anon, authenticated;
grant execute on function public.claim_code(text, uuid, integer) to service_role;
