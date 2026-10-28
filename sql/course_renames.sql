-- SilverCircle: class names now match the course request sheets. Rows written
-- under the app's first names are renamed here. The app reads the old names
-- as the new ones in the meantime, so this can run whenever.
do $$
declare r record;
begin
  for r in select * from (values
    ('Algebra I','Algebra'), ('Algebra II','Algebra 2'), ('Precalculus','Pre-Calculus'), ('AP Precalculus','AP Pre-Calculus'),
    ('AP Physics','AP Physics 1'), ('US History','Modern US History'), ('AP US History','AP United States History'),
    ('AP English Lang','AP Lang/Comp'), ('Financial Accounting','ACC:142 Financial Accounting')
  ) as v(old, new) loop
    update sl_student_classes set course = r.new where course = r.old and not exists (select 1 from sl_student_classes x where x.user_id = sl_student_classes.user_id and x.course = r.new);
    delete from sl_student_classes where course = r.old;
    update sl_tutor_courses set course = r.new where course = r.old and not exists (select 1 from sl_tutor_courses x where x.user_id = sl_tutor_courses.user_id and x.course = r.new);
    delete from sl_tutor_courses where course = r.old;
    update sl_grades set course = r.new where course = r.old and not exists (select 1 from sl_grades x where x.user_id = sl_grades.user_id and x.course = r.new);
    delete from sl_grades where course = r.old;
    update sl_requests set course = r.new where course = r.old;
    update sl_posts set course = r.new where course = r.old;
    update sl_materials set course = r.new where course = r.old;
    update sl_events set course = r.new where course = r.old;
  end loop;
end $$;
