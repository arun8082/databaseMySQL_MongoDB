/*1.*/
DROP function compute_salary;
delimiter //
CREATE FUNCTION compute_salary(pemp_no int) RETURNS DECIMAL(9,2)
BEGIN
	DECLARE DA INT DEFAULT 15;
	DECLARE HRA INT DEFAULT 20;
	DECLARE TA INT DEFAULT 8;
	
	DECLARE vsalary int;
	DECLARE vincrement int;
	DECLARE vexperience int;
	DECLARE vresult decimal(9,2);
	
	SELECT sal,floor(datediff(curdate(),hiredate)/365)
	INTO vsalary, vexperience
	FROM emp
	WHERE empno=pemp_no;
	
	IF vexperience<1 THEN
		SET vincrement=0;
		ELSEIF vexperience<2 THEN
		SET vincrement=10;
		ELSEIF vexperience<4 THEN
		SET vincrement=20;
		ELSE
		SET vincrement=30;
	END IF;
	
	SET vsalary=vsalary+ vsalary*(DA/100) + vsalary*(HRA/100) + vsalary*(TA/100);
	SET vresult=vsalary*(1+(vincrement/100));
	
	RETURN vresult;
END//
delimiter ;	

/*2***********************************************************************************/
DROP PROCEDURE emp_information;
delimiter //
CREATE PROCEDURE emp_information()
BEGIN
	
SELECT e.ename,d.dname,e.job,e.sal,CASE 
	WHEN e.sal<(SELECT avg(sal) FROM emp WHERE deptno=e.deptno GROUP BY deptno) THEN 'Lesser'
	WHEN e.sal>(SELECT avg(sal) FROM emp WHERE deptno=e.deptno GROUP BY deptno) THEN 'Greater'
	WHEN e.sal=(SELECT avg(sal) FROM emp WHERE deptno=e.deptno GROUP BY deptno) THEN 'Equal'
	ELSE 'Nil'
	END as Remark
	FROM emp e INNER JOIN dept d
	ON e.deptno=d.deptno;
	
END//
delimiter ;
call emp_information;

/*5***********************************************************************************/
CREATE TABLE emp_back
AS
SELECT * FROM emp WHERE 1=2;
ALTER TABLE emp_back
ADD COLUMN old_salary decimal(7,2)
AFTER sal;

DROP PROCEDURE emp_update;
delimiter //
CREATE PROCEDURE emp_update(IN pemp_no int)
BEGIN
	DECLARE vsal decimal(7,2);
	DECLARE vexperience int default 0;
	DECLARE vincrement int default 0;
	
	DECLARE vempno int;
	DECLARE vename varchar(50);
	DECLARE vjob varchar(50);
	DECLARE vmgr varchar(50);
	DECLARE vhiredate date;
	DECLARE vcomm decimal(7,2);
	DECLARE vdeptno varchar(50);
	
	SELECT sal,TIMESTAMPDIFF(year,hiredate,curdate()),
			empno,ename,job,mgr,hiredate,comm,deptno
	INTO vsal,vexperience,
			vempno,vename,vjob,vmgr,vhiredate,vcomm,vdeptno
	FROM emp	
	WHERE empno=pemp_no;
		
	IF vexperience<2 THEN
		SET vincrement=0;
	ELSEIF vexperience<5 THEN
		SET vincrement=20;
	ELSE
		SET vincrement=25;
	END IF;
	
	UPDATE emp
	SET sal=vsal*(1+(vincrement/100))
	WHERE empno=pemp_no;
	
	INSERT INTO emp_back(empno,ename,job,mgr,hiredate,sal,old_salary,comm,deptno)
	VALUE (vempno,vename,vjob,vmgr,vhiredate,vsal*(1+(vincrement/100)),vsal,vcomm,vdeptno);
	
END//
delimiter ;
call emp_update(7499);

/*6.1***********************************************************************************/
CREATE TABLE emp_allowance(
		empno int,
		experience int,
		hiredate date,
		allowance decimal(7,2)		
);
/*Function to calculate_experience as 1.4=1 && 1.5=2*/
DROP FUNCTION calculate_experience;
delimiter //
CREATE FUNCTION calculate_experience(pemp_id int) RETURNS int
BEGIN
	DECLARE vexperience int;
	
	SELECT ROUND(timestampdiff(MONTH,hiredate,curdate())/12)
	INTO vexperience
	FROM emp
	WHERE empno=pemp_id;
	
	RETURN vexperience;
END//
delimiter ;
select timestampdiff(month,hiredate,curdate())/12,calculate_experience(empno) from emp;

/*Procedure to calculate_aditional_allowances and insert data into aditional_allowance*/
DROP PROCEDURE aditional_allowances;
delimiter //
CREATE PROCEDURE aditional_allowances(IN pemp_id int)
BEGIN
	DECLARE vexperience int;
	DECLARE vhiredate date;
	DECLARE vaditional_allowances decimal(15,2);
	
	SELECT calculate_experience(pemp_id),hiredate
	INTO vexperience,vhiredate
	FROM emp
	WHERE empno=pemp_id;
	
	SET vaditional_allowances=vexperience*3000;
	
	INSERT INTO emp_allowance(empno,experience,hiredate,allowance)
	VALUES (pemp_id,vexperience,vhiredate,vaditional_allowances);
	
END//
delimiter ;
call aditional_allowances(7499);


/*6.2***********************************************************************************/
CREATE TABLE order_history_backup(
	orderid int,
	old_qty int,
	new_qty int,
	old_cost decimal(7,2),
	new_cost decimal(7,2),
	updated datetime
);

CREATE TABLE order_history(
		orderid int,
		order_qty int,
		order_cost int,
		order_date date
);
INSERT into order_history values(1,23,455,'2019-04-01');

/*Update trigger to store data in the order_history table in case of updation*/
drop trigger order_history_trigger;
delimiter //
CREATE TRIGGER order_history_trigger 
BEFORE UPDATE ON order_history
FOR EACH ROW
BEGIN
	INSERT INTO order_history_backup(orderid,old_qty,new_qty,old_cost,new_cost,updated)
	VALUES(OLD.orderid,OLD.order_qty,NEW.order_qty,OLD.order_cost,NEW.order_cost,now());
END//
delimiter ;

UPDATE order_history
SET order_qty=78
WHERE orderid=1;


CREATE TABLE emp_audit
AS
SELECT * from emp where 1=2;
/*insert trigger for emp table*/
drop trigger emp_insert_trigger;
delimiter //
CREATE TRIGGER emp_insert_trigger
BEFORE INSERT ON emp
FOR EACH ROW
BEGIN
INSERT INTO emp_audit(empno,ename,job,mgr,hiredate,sal,comm,deptno,updated,action)
VALUES(NEW.empno,NEW.ename,NEW.job,NEW.mgr,NEW.hiredate,NEW.sal,NEW.comm,NEW.deptno,now(),'insert');

END//
delimiter ;

/*insert trigger for emp table*/
drop trigger emp_delete_trigger;
delimiter //
CREATE TRIGGER emp_delete_trigger
BEFORE DELETE ON emp
FOR EACH ROW
BEGIN
INSERT INTO emp_audit(empno,ename,job,mgr,hiredate,sal,comm,deptno,updated,action)
VALUES(OLD.empno,OLD.ename,OLD.job,OLD.mgr,OLD.hiredate,OLD.sal,OLD.comm,OLD.deptno,now(),'delete');

END//
delimiter ;

/*_***********************************************************************************/
