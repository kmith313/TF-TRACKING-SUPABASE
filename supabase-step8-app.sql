-- STEP 8: what the new Summary / Comparison screen needs on top of steps 1-7.  Run ONCE in the SQL Editor (after step 7).
-- (a) list_json gets two more optional filters (PR date from / to) for the "Pending for issue - age wise" numbers.
-- (b) compare2_json = same as compare_json but WITHOUT the substation column: the new screen has no substation view, so the answer is about 3x smaller (saves egress).
-- (c) password_changed() lets a user clear his own "must change password" flag after he changed it.

-- (a)
-- list behind a number of the Summary: the records of ONE metric (0..14, same meaning as in summary_agg).
-- p_limit rows per call (default 300, to save data transfer), p_offset = how many rows were already loaded ("Load more" button).
drop function if exists public.list_json(int, date, date, date, text, text[], text[], int[], date);
drop function if exists public.list_json(int, date, date, date, text, text[], text[], int[], date, int, int);
create or replace function public.list_json(p_metric int, p_date date, p_from date, p_to date,
                                            p_ws text default null, p_divs text[] default null, p_subs text[] default null,
                                            p_caps int[] default null, p_prd date default null,
                                            p_limit int default 300, p_offset int default 0,
                                            p_prd_from date default null, p_prd_to date default null)
returns jsonb language sql stable security invoker set search_path = public as
$$
  with r as (
    select d.*, coalesce(d.pr_date, date '1900-01-01') as pr
      from public.data d
     where (p_ws is null or d.workshop = p_ws)
       and (p_caps is null or coalesce(d.capacity, 0) = any (p_caps))
       and (p_divs is null or upper(btrim(regexp_replace(coalesce(d.division,''),  '\s+', ' ', 'g'))) = any (p_divs))
       and (p_subs is null or upper(btrim(regexp_replace(coalesce(d.substation,''),'\s+', ' ', 'g'))) = any (p_subs))
       and (p_prd is null or d.pr_date = p_prd)
       and (p_prd_from is null or coalesce(d.pr_date, date '1900-01-01') >= p_prd_from)
       and (p_prd_to   is null or coalesce(d.pr_date, date '1900-01-01') <= p_prd_to)
  ), h as (
    select r.*,
      case when r.dup then (p_metric = 14 and r.pr between p_from and p_to)
      else case p_metric
        when 0  then r.pr < p_from and (r.issue_date is null or r.issue_date >= p_from) and (r.return_date is null or r.return_date > p_from - 1)
        when 1  then r.pr = p_date
        when 2  then r.pr = p_date and r.issue_date is not null
        when 3  then r.pr = p_date and r.repl_date is not null
        when 4  then r.issue_date = p_date
        when 5  then r.repl_date = p_date
        when 6  then r.pr between p_from and p_to
        when 7  then r.issue_date between p_from and p_to
        when 8  then r.repl_date between p_from and p_to
        when 9  then r.pr <= p_to and (r.issue_date is null or r.issue_date > p_to) and (r.return_date is null or r.return_date > p_to)
        when 10 then r.issue_date is not null and r.issue_date <= p_to and (r.repl_date is null or r.repl_date > p_to) and (r.return_date is null or r.return_date > p_to)
        when 11 then r.return_date = p_date
        when 12 then r.return_date between p_from and p_to
        when 13 then r.repl_date is not null and r.repl_date <= p_to and (r.return_date is null or r.return_date > p_to)
        else false end
      end as hit
    from r
  ), top as (
    select d.* from public.data d
      join (select id from h where hit order by pr, pr_no collate "C" limit least(greatest(p_limit, 1), 2000) offset greatest(p_offset, 0)) k on k.id = d.id
  )
  select jsonb_build_object(
    'total', (select count(*) from h where hit),
    'rows', coalesce((select jsonb_agg(public.row20(t) || to_jsonb((select case when public.can_edit_rows() then 1 else 0 end)) order by coalesce(t.pr_date, date '1900-01-01'), t.pr_no collate "C") from top t), '[]'::jsonb))
$$;


-- (b) [period, day_offset, workshop, division, capacity, n]
create or replace function public.compare2_json(p_from date, p_to date, p_div text default null, p_day boolean default false)
returns jsonb language sql stable security invoker set search_path = public as
$$
  select coalesce(jsonb_agg(jsonb_build_array(period, off, workshop, division, capacity, n)), '[]'::jsonb)
    from (select period, off, workshop, division, capacity, sum(n)::bigint as n
            from public.compare_agg(p_from, p_to, p_div, p_day)
           group by 1, 2, 3, 4, 5 order by 1, 2, 3, 4, 5) x
$$;

-- (c)
create or replace function public.password_changed() returns void language sql security definer set search_path = public as
$$ update public.profiles set must_change = false where user_id = auth.uid() $$;

grant execute on function
  public.list_json(int, date, date, date, text, text[], text[], int[], date, int, int, date, date),
  public.compare2_json(date, date, text, boolean),
  public.password_changed() to authenticated;
