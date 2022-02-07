----http://web2py.com/books/default/chapter/29/05/the-views#HTML-helpers----
----http://www.web2py.com/init/default/examples----


 CREATE TABLE `users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) DEFAULT NULL,
  `login` varchar(50) NOT NULL unique,
  `password` varchar(100) NOT NULL,
  PRIMARY KEY (`id`));

  CREATE TABLE `contas` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `id_utilizador` int(11) unsigned NOT NULL,
  `saldo` decimal(9,2) unsigned NOT NULL DEFAULT 0.00,
  `tipo` varchar(50) NOT NULL default "ordem",
  PRIMARY KEY (`id`),
  KEY `id_utilizador` (`id_utilizador`),
  CONSTRAINT `contas_ibfk_1` FOREIGN KEY (`id_utilizador`) REFERENCES `users` (`id`) on delete cascade);

CREATE TABLE `transferencias` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `conta_origem` int(11) unsigned NOT NULL,
  `conta_destino` int(11) unsigned NOT NULL,
  `operacao` varchar(30) DEFAULT NULL,
  `valor` decimal(9,2) NOT NULL,
  `data` datetime not null,
  PRIMARY KEY (`id`),
  KEY `conta_origem` (`conta_origem`),
  KEY `conta_destino` (`conta_destino`),
  CONSTRAINT `transferencias_ibfk_1` FOREIGN KEY (`conta_origem`) REFERENCES `contas` (`id`) on delete cascade,
  CONSTRAINT `transferencias_ibfk_2` FOREIGN KEY (`conta_destino`) REFERENCES `contas` (`id`) on delete cascade);

  CREATE TABLE `movimentos` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) unsigned NOT NULL,
  `transferencia_id` int(11) unsigned NULL,
  `interno` int(1) unsigned not null,
  `operacao` varchar(30) NOT NULL,
  `valor` decimal(9,2) NOT NULL,
  `data` datetime not null,
  PRIMARY KEY (`id`),
  KEY `transferencia_id` (`transferencia_id`),
  CONSTRAINT `movimentos_ibfk_1` FOREIGN KEY (`transferencia_id`) REFERENCES `transferencias` (`id`) on delete cascade,
  CONSTRAINT `movimentos_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) on delete cascade);

  


alter table movimentos add foreign key (user_id) references users(id) on delete cascade;

ALTER TABLE tablename AUTO_INCREMENT = 1;

DELIMITER //
CREATE PROCEDURE efetuarTransferencia(in inUserOrigem int(10),in inUserDestino int(10), in inValorAEnviar decimal(7,2))
BEGIN
    declare allowed int(1);
    declare IDtransferencia int(10);
    declare contaIDorigem int(10);
    declare contaIDdestino int(10);
    declare userDestinoExists int(1);
    set allowed=0;
    set IDtransferencia=0;

    select count(id) into allowed from contas where id_utilizador=inUserOrigem and saldo>= inValorAEnviar and contas.tipo='ordem';
    select count(id) into userDestinoExists from contas where id_utilizador=inUserDestino and contas.tipo='ordem';

    IF allowed = 1 AND userDestinoExists = 1 AND inUserOrigem != inUserDestino THEN
        select contas.id into contaIDorigem from contas join users on users.id=contas.id_utilizador where users.id=inUserOrigem and contas.tipo='ordem';
        select contas.id into contaIDdestino from contas join users on users.id=contas.id_utilizador where users.id=inUserDestino and contas.tipo='ordem';
        update contas set saldo=saldo-inValorAEnviar where id_utilizador=inUserOrigem and tipo='ordem';
        insert into transferencias values (default,contaIDorigem, contaIDdestino, 'externa',inValorAEnviar, NOW());
        select LAST_INSERT_ID() into IDtransferencia;
        insert into movimentos values(default,inUserOrigem,IDtransferencia,0,'debitar', -inValorAEnviar, now());
        insert into movimentos values(default,inUserDestino,IDtransferencia,0,'creditar', inValorAEnviar,now());
        update contas set saldo=saldo+inValorAEnviar where id=contaIDdestino;
    ELSEIF userDestinoExists = 0 THEN
        select "ID de User destino nao existe" as Erro;
    ELSE
        select "Nao e possivel efetuar transferencia" as Erro;
    END IF;

END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE efetuarTransferenciaInterna(in inIDUser int(11),in inTipoContaOrg varchar(30), in inTipoContaDest varchar(30), in inValorATransferir decimal(7,2))
BEGIN
    declare allowed int(5);
    declare IDtransferencia int(10);
    declare IDcontaOrg int(5);
    declare IDcontaDest int(5);
    set allowed=0;
    set IDcontaOrg=0;
    set IDcontaDest=0;
    select count(id) into allowed from contas where id_utilizador=inIDUser and saldo>=inValorATransferir and tipo=inTipoContaOrg;
    IF allowed >= 1 THEN
        IF inTipoContaDest NOT LIKE inTipoContaOrg THEN
            IF inTipoContaOrg LIKE (select tipo from contas where id_utilizador=inIDUser and tipo=inTipoContaOrg) AND inTipoContaDest LIKE (select tipo from contas where id_utilizador=inIDUser and tipo=inTipoContaDest) THEN
                select id into IDcontaOrg from contas where id_utilizador=inIDUser and tipo=inTipoContaOrg;
                update contas set saldo=saldo-inValorATransferir where id=IDcontaOrg;
                select id into IDcontaDest from contas where id_utilizador=inIDUser and tipo=inTipoContaDest;
                update contas set saldo=saldo+inValorATransferir where id=IDcontaDest;
                insert into transferencias values (default,IDcontaOrg,IDcontaDest,'interna',inValorATransferir,NOW());
                select LAST_INSERT_ID() into IDtransferencia;
                insert into movimentos values(default,inIDUser,IDtransferencia,1,'debitar', -inValorATransferir,now());
                insert into movimentos values(default,inIDUser,IDtransferencia,1,'creditar', inValorATransferir,now());
            ELSE
                select "Contas nao encontradas" as Erro;
            END IF;
        ELSE
            select "Nao podes fazer transferencia para a mesma conta" as Erro;
        END IF;
    ELSE
        select "Nao e possivel efetuar transferencia" as Erro;
    END IF;

END //
DELIMITER ;


DELIMITER //
CREATE PROCEDURE mostrarTransferencias(in inIDUser int(10), in inOperacao varchar(30))
BEGIN

    IF inOperacao is NULL THEN
        select t.id, userorg.nome As Origem, userdest.nome as Destino, org.tipo as origemTipo, dest.tipo as destTipo, t.valor, t.data from transferencias t join contas org on org.id=t.conta_origem join contas dest on dest.id=t.conta_destino join users userorg on org.id_utilizador=userorg.id join users userdest on dest.id_utilizador=userdest.id where (userorg.id=inIDUser or userdest.id=inIDUser) order by t.data desc;

    ELSEIF inOperacao = 'externa' THEN
        select t.id, userorg.nome As Origem, userdest.nome as Destino, t.valor, t.data from transferencias t join contas org on org.id=t.conta_origem join contas dest on dest.id=t.conta_destino join users userorg on org.id_utilizador=userorg.id join users userdest on dest.id_utilizador=userdest.id where t.operacao=inOperacao and (userorg.id=inIDUser or userdest.id=inIDUser)  order by t.data desc;

    ELSEIF inOperacao = 'interna' THEN
        select t.id, userorg.nome As Utilizador, org.tipo as origemTipo, dest.tipo as destTipo, t.valor, t.data from transferencias t join contas org on org.id=t.conta_origem join contas dest on dest.id=t.conta_destino join users userorg on org.id_utilizador=userorg.id join users userdest on dest.id_utilizador=userdest.id where userorg.id=inIDUser and t.operacao=inOperacao order by t.data desc;
    END IF;
    
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE criarUser(in inNome varchar(20), in inUser varchar(20),in inPass varchar(100))
BEGIN
    declare allowed int(1);
    declare IDuser int(11);
    set allowed=0;
    set IDuser=0;
    select count(id) into allowed from users where login=inUser;
    IF allowed = 0 THEN
        insert into users(nome,login,password) values (inNome, inUser,inPass);
        select LAST_INSERT_ID() into IDuser;
        insert into contas (id_utilizador,saldo,tipo) values (IDuser,0,'ordem');
        insert into contas (id_utilizador,saldo,tipo) values (IDuser,0,'prazo');
    ELSE 
        select "Username indisponivel" as Erro;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE autenticaUtilizador(in inUser varchar(20),in inPass varchar(100))
BEGIN
    select * from users where login=inUser and password=inPass;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE efetuarDeposito(in inIDUser int(10), in inValorDepositar decimal(7,2))
BEGIN

    update contas set saldo=saldo+inValorDepositar where id_utilizador=inIDUser and tipo='ordem';
    insert into movimentos values (default,inIDUser,NULL,0,'deposito', inValorDepositar,now());
    
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE efetuarLevantamento(in inIDUser int(10), in inValorLevantar decimal(7,2))
BEGIN
    declare allowed int(1);
    set allowed=0;
    select count(id) into allowed from contas where id_utilizador=inIDUser and tipo='ordem' and saldo>=inValorLevantar;
    IF allowed = 1 THEN
        update contas set saldo=saldo-inValorLevantar where id_utilizador=inIDUser and tipo='ordem';
        insert into movimentos values (default,inIDUser,NULL,0,'levantamento', -inValorLevantar, NOW());
    ELSE 
        select "Nao tens saldo suficiente" as Erro;
    END IF;
    
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE mostrarUtilizadores(in inIDExcluir int(10))
BEGIN
    IF inIDExcluir is NULL THEN
        select id, nome as Nome from users;
    ELSE 
    select id,nome as Nome from users where id != inIDExcluir;
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE mostrarSaldo(in inIDUser int(10), in inTipo varchar(50))
BEGIN

    IF inTipo is NULL THEN
        select sum(saldo) as Saldo from contas where id_utilizador=inIDUser;
    ELSEIF inTipo = 'ordem' THEN 
        select saldo as Saldo from contas where id_utilizador=inIDUser and tipo=inTipo;
    ELSEIF inTipo = 'prazo' THEN
        select saldo as Saldo from contas where id_utilizador=inIDUser and tipo=inTipo; 
    END IF;   

END //
DELIMITER ;


(mandar inTipo NULL para ver tudo)
DELIMITER //
CREATE PROCEDURE mostrarMovimentos(in inIDUser int(10), in inTipo varchar(50))
BEGIN

    IF inTipo is NULL THEN
        select m.id, user.nome as Nome, m.transferencia_id, m.operacao, m.valor, m.data from movimentos m join users user on m.user_id=user.id where user.id=inIDUser order by data desc;
    ELSE
        select m.id, user.nome as Nome, m.transferencia_id, m.operacao, m.valor, m.data from movimentos m join users user on m.user_id=user.id where user.id=inIDUser and m.operacao=inTipo order by data desc;
    END IF;   

END //
DELIMITER ;



select m.id, user.nome as Nome, m.transferencia_id, m.operacao, m.valor from movimentos m join users user on m.user_id=user.id where user.id=1;

select t.id, userorg.nome As Origem, userdest.nome as Destino, t.operacao, org.tipo as origemTipo, dest.tipo as destTipo, t.valor, t.data from transferencias t join contas org on org.id=t.conta_origem join contas dest on dest.id=t.conta_destino join users userorg on org.id_utilizador=userorg.id join users userdest on dest.id_utilizador=userdest.id where userorg.id=3 and t.operacao='externa' order by t.data;

select transferencias.conta_origem as IDOrigem, orign.login, transferencias.operacao, transferencias.valor, transferencias.conta_destino as UserDestino, dest.login 
from transferencias 
join users as orign 
on transferencias.user_origem=orign.id 
join users as dest on
 transferencias.user_destino=dest.id;

select transferencias.user_origem as IDOrigem, orign.login, transferencias.valor, transferencias.user_destino as UserDestino, dest.login, transferencias.datahora  from transferencias  join users as orign  on transferencias.user_origem=orign.id  join users as dest on  transferencias.user_destino=dest.id;

select i.id, users.login, i.transferencia_id, i.operacao, i.valor from movimentos i join users on i.user_id=users.id order by (i.id);

select transferencias.user_origem as IDOrigem,orign.login,transferencias.operacao,transferencias.valor, transferencias.user_destino as UserDestino, dest.login from transferencias join users as orign on transferencias.user_origem=orign.id join users as dest on transferencias.user_destino=dest.id where transferencias.user_origem=1; (de um user especifico)


select orign.login as UserOrigem,transferencias.operacao,transferencias.valor, dest.login as UserDestino from transferencias join users as orign on transferencias.user_origem=orign.id join users as dest on transferencias.user_destino=dest.id where transferencias.user_origem=1;


select movimentos.id,users.login, movimentos.transferencia_id, movimentos.operacao, movimentos.valor from movimentos join users on users.id=movimentos.user_id order by (movimentos.id);

select i.id, orig.login as UserOrigem, dest.login as UserDest, mov.operacao, i.valor from transferencias i join users as orig on i.user_origem=orig.id join users as dest on i.conta_destino=dest.id join movimentos as mov on i.conta_origem=mov.user_id group by id;

select contas.id, users.login, contas.saldo from contas join users on contas.id_utilizador=users.id;

select contas.id, users.login, contas.saldo, contas.tipo from contas join users on contas.id_utilizador=users.id;
(mostra os tipos de contas e os logins)

select contas.id, users.login, sum(contas.saldo) as SaldoTotal from contas join users on contas.id_utilizador=users.id where users.login='';
(mostra a soma total de saldo das contas de utilizadores)

select t.id, org.id_utilizador, dest.id_utilizador, t.operacao, t.valor, t.data from transferencias t
join contas org on org.id=t.conta_origem
join contas dest on dest.id=t.conta_destino
join users on org.id_utilizador=users.id;
(faz a associacao de contaID com userID)

select t.id, userorg.login, userdest.login, t.operacao, org.tipo as origemTipo, dest.tipo as destTipo, t.valor, t.data from transferencias t
join contas org on org.id=t.conta_origem
join contas dest on dest.id=t.conta_destino
join users userorg on org.id_utilizador=userorg.id
join users userdest on dest.id_utilizador=userdest.id
where userorg.login='joaquimz'
order by t.data;
(faz a associacao de contaID com userID e mostra username)

select t.id, userorg.nome As Origem, userdest.nome as Destino, t.operacao, t.valor, t.data from transferencias t join contas org on org.id=t.conta_origem join contas dest on dest.id=t.conta_destino join users userorg on org.id_utilizador=userorg.id join users userdest on dest.id_utilizador=userdest.id where userorg.id= and t.operacao='externa' order by t.data;

select t.id, userorg.login, userdest.login, t.operacao, org.tipo as origemTipo, dest.tipo as destTipo, t.valor, t.data from transferencias t 
join contas org on org.id=t.conta_origem 
join contas dest on dest.id=t.conta_destino 
join users userorg on org.id_utilizador=userorg.id 
join users userdest on dest.id_utilizador=userdest.id
order by t.data;
(faz associacao das contaID com userID, mostra username e mostra o tipo de conta 'ordem' ou 'prazo')
