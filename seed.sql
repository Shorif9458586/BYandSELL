-- Optional demo seed after schema.sql.
insert into public.services(name_bn,name_en,slug,description,official_fee,other_cost,service_fee,commission_type,commission_value,estimated_time,disclaimer)
select 'নামজারি সহায়তা','Mutation Assistance','namjari','নামজারি আবেদন প্রস্তুতি ও document checklist assistance',0,0,400,'fixed',200,'প্রক্রিয়া-নির্ভর','সরকারি অনুমোদনের নিশ্চয়তা নয়।'
where not exists(select 1 from public.services where slug='namjari');
insert into public.services(name_bn,name_en,slug,description,official_fee,other_cost,service_fee,commission_type,commission_value,estimated_time,disclaimer)
select 'খতিয়ান / পরচা সহায়তা','Khatian / Porcha Assistance','khatian','খতিয়ান/পরচা সম্পর্কিত তথ্য ও document assistance',0,0,300,'fixed',100,'প্রক্রিয়া-নির্ভর','ডকুমেন্ট ইস্যুর নিশ্চয়তা নয়।'
where not exists(select 1 from public.services where slug='khatian');