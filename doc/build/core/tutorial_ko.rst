.. _sqlexpression_toplevel_ko:

================================
SQL 표현 언어 튜토리얼
================================

SQLAlchemy 표현식 언어는 관계형 데이터베이스 구조와 표현식을 파이썬 구문을 사용하여
나타내는 시스템을 제공한다. 이 구문들은 데이터베이스 백엔드 사이의 다양한 구현 차이를
조금 추상화해서 제공하면서 아래에 있는 데이터베이스와 가능한 유사하도록
모델링 되었다. 구문들은 백엔드 사이의 동일한 컨셉을 동일한 구조로
표현하려고 하는 반면 백엔드의 특정 서브셋에 유일하게 있는 유용한 컨셉들은
숨기지 않는다. 그러므로 표현식 언어는 백엔드에 중립적인 SQL 표현식을 쓰는 방식을
제공하지만 표현식이 백엔드 중립적이도록 강제하려고 하지는 않는다.

표현식 언어는 표현식 언어의 최상단에 빌드되어 있는 개별적 API인 객체 관계형 매퍼와는
다르다. :ref:`ormtutorial_toplevel`\ 에 설명되어있는 ORM은 그 자체로 응용된 표현식 언어의
예시가 되는 고수준의 추상적인 사용 패턴을 제공하지만 표현식 언어는 직접적으로 관계형 데이터베이스의
원시적인 구문을 표현하는 시스템을 제공한다.

ORM과 표현식 언어의 사용 패턴 사이에 겹치는 부분이 존재하는 반면, 유사점은 처음
나타나는 것보다 더 피상적이다. ORM은 하부의 스토리지 모델로부터 투명하게 유지되고
갱신되는 사용자 정의 `domain model <http://en.wikipedia.org/wiki/Domain_model>`_\ 의
관점에서 데이터와 구조에 접근한다. 표현식 언어는 데이버베이스에서 개별적으로 소비되는
메세지로 명시적으로 구성되는 리터럴 스키마와 SQL 표현식 관점에서 접근한다.

성공적인 어플리케이션은 비록 어플리케이션 개념을 개별적인 데이터베이스 메세지로 번역하고
개별적인 데이터베이스 결과 세트에서 어플리케이션 개념으로 번역하는 자체 시스템을
정의해야 할 필요가 있지만 표현식 언어만 사용해서 제작될 수 있습니다.
대신에 ORM으로 만들어진 어플리케이션은 고급 수준의 시나리오에서 종종 표현식 언어를
특정 데이터베이스와의 상호작용이 필요한 부분에 직접적으로 사용해야 한다.

아래의 튜토리얼은 doctest 포맷으로 되어 있으며 각 ``>>>`` 줄은
파이썬 커맨드 프롬프트에서 타입할 수 있는 것을 나타내며 그 다음의 텍스트는
예상되는 반환 값을 나타낸다. 이 튜토리얼은 선수 과목 같은 것은 없다.

버전 확인
=============


최소한 SQLAlchemy **1.2 버전**\ 을 사용하고 있는지 확인하자:

.. sourcecode:: pycon+sql

    >>> import sqlalchemy
    >>> sqlalchemy.__version__  # doctest: +SKIP
    1.2.0

연결
==========

이 튜토리얼을 위해서 우리는 메모리에만 저장되는 SQLite 데이터베이스를 사용할 것이다.
이 방식은 어딘가에 정의된 실제 데이터베이스 필요 없이 테스르를 할 수 있는 방식이다.
:func:`~sqlalchemy.create_engine`\ 를 사용해서 연결할 것이다:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy import create_engine
    >>> engine = create_engine('sqlite:///:memory:', echo=True)

``echo`` 플래그는 SQLAlchemy가 파이썬의 기본 ``logging`` 모듈을 통해서 로그를 기록하도록
설정하는 숏컷이다. 사용하도록 설정해 놓으면 생성되는 모든 SQL을 볼 수 있을 것이다. 이 튜토리얼을
진행하면서 출력이 적게 생성되기를 바란다면 ``False``\ 로 설정해놓으면 된다.
이 튜토리얼은 SQL을 팝업창 뒤에서 포매팅하기 때문에 전면에 나타나지는 않을 것이다;
"SQL" 링크를 클릭해서 무엇이 생성되었는지 확인하라.

:func:`.create_engine`\ 의 반환값은 :class:`.Engine`\ 의 인스턴스이며,
사용중인 :term:`DBAPI`\ 와 데이터베이스의 세부 사항을 다루는 :term:`dialect`\ 가
적용이 된 데이터베이스의 코어 인터페이스다. 이 경우 SQLite dialect가
파이썬 빌트인 ``sqlite3`` 모듈에 대한 지시사항을 해석할 것이다.

.. sidebar:: Lazy Connecting

    :func:`.create_engine`\ 으로 처음 반환되었을 때 :class:`.Engine`\ 는
    실제로 데이터 베이스에 연결을 시도하지 않는다; 연결은 데이버베이스에 대한
    작업을 수행하도록 최초로 요쳥되었을 때 일어난다.

:meth:`.Engine.execute`\ 나 :meth:`.Engine.connect` 같은 메서드가 처음 호출되었을 때,
:class:`.Engine`\ 는 데이터베이스로 SQL을 전송하기 위한 실제 :term:`DBAPI` 연결을 구축한다.

.. seealso::

    :ref:`database_urls`\ 에는 여러 종류의 데이터베이스에 연결하는 :func:`.create_engine` 예시와
    함께 추가적인 정보가 있는 링크를 포함하고 있다.

테이블 정의하고 생성하기
========================

SQL 표현식 언어는 대부분의 경우 테이블의 컬럼에 대해 표현식을 생성한다.
SQLAlchemy에서 컬럼은 대부분 :class:`~sqlalchemy.schema.Column`\ 이라고 하는
객체로 표현되며 모든 경우에 :class:`~sqlalchemy.schema.Column` 은
:class:`~sqlalchemy.schema.Table`\ 과 연결되어 있다.
:class:`~sqlalchemy.schema.Table` 객체와 연결된 자식 객체의 집합은 **데이터베이스 메타데이터**
라고 한다. 이 튜토리얼에서는 명시적으로 :class:`~sqlalchemy.schema.Table` 객체를 레이아웃할
것이지만 SA는 존재하는 데이터베이스에서 :class:`~sqlalchemy.schema.Table` 전체 객체 세트를 자동적으로
"임포트"할 수도 있다(이 프로세스를 **테이블 리플렉션**\ 이라고 한다).

우리는 일반 SQL의 CREATE TABLE 명령문과 유사한 :class:`~sqlalchemy.schema.Table` 구문을 사용해서
모드느 테이블을 :class:`~sqlalchemy.schema.MetaData`\ 라고 불리는 카탈로그에 정의할 수 있다.
우리는 두 개의 테이블을 만들 것이며, 하나는 어플리케이션의 "users"를 나타낸다, 다른 하나는
"users" 테이블의 각 행에 대한 "email addresses"를 나타낸다:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey
    >>> metadata = MetaData()
    >>> users = Table('users', metadata,
    ...     Column('id', Integer, primary_key=True),
    ...     Column('name', String),
    ...     Column('fullname', String),
    ... )

    >>> addresses = Table('addresses', metadata,
    ...   Column('id', Integer, primary_key=True),
    ...   Column('user_id', None, ForeignKey('users.id')),
    ...   Column('email_address', String, nullable=False)
    ...  )

:class:`~sqlalchemy.schema.Table` 객체를 정의하거나, 존재하는 데이터베이스에서
자동적으로 객체를 생성하는 방법에 대한 모든 내용은 :ref:`metadata_toplevel`\ 에서
확인할 수 있다.

그 다음, :class:`~sqlalchemy.schema.MetaData`\ 에 우리가 실제로
SQLite 데이터베이스 안에 우리가 선택한 테이블을 생성하겠다는 지시를 전달하기 위해,
:func:`~sqlalchemy.schema.MetaData.create_all`\ 를 사용해서 우리의 데이터베이스를
가리키는 ``engine`` 인스턴스를 전달할 것이다. 그러면 테이블 생성 전에
먼저 테이블의 존재여부를 확인해서, 여러 번 호출을 해도 안전하다. ::

.. sourcecode:: pycon+sql

    {sql}>>> metadata.create_all(engine)
    SE...
    CREATE TABLE users (
        id INTEGER NOT NULL,
        name VARCHAR,
        fullname VARCHAR,
        PRIMARY KEY (id)
    )
    ()
    COMMIT
    CREATE TABLE addresses (
        id INTEGER NOT NULL,
        user_id INTEGER,
        email_address VARCHAR NOT NULL,
        PRIMARY KEY (id),
        FOREIGN KEY(user_id) REFERENCES users (id)
    )
    ()
    COMMIT

.. note::

    CREATE TABLE 신택스에 친숙한 사용자들은 VARCHAR 컬럼이 length 지정 없이 생성되었다는
    점을 알아차렸을 것이다; SQLite나 PostgreSQL에서 이는 유요한 데이터 타입이지만, 다른
    곳에서는 허용되지 않는다. 그래서 만약 이 튜토리얼을 다른 데이터베이스에서 실행햐고 있고
    SQLAlchemy를 사용해 CREATE TABLE를 발행하고 싶으면 "length"는 아래와 같이
    :class:`~sqlalchemy.types.String`\ 에 제공된다. ::

        Column('name', String(50))

    :class:`~sqlalchemy.types.String`\ 의 length 필드뿐만 아니라 유사한 :class:`~sqlalchemy.types.Integer`,
    :class:`~sqlalchemy.types.Numeric`\ 의 precision/scale 필드는 테이블을 생성할 때를 제외하고는
    SQLAlchemy에 의해 참조되지 않는다.

    게다가, Firebird와 Oracle은 새로운 primary key 식별자를 생성하기 위해서 시퀀스를 요구하며
    SQLAlchemy는 지시 없이 그런 것들을 가정하거나 생성하지 않는다.
    그 부분에 대해서는 :class:`~sqlalchemy.schema.Sequence` 구문을 사용하면 된다. ::

        from sqlalchemy import Sequence
        Column('id', Integer, Sequence('user_id_seq'), primary_key=True)

    매우 간단한 전체 :class:`~sqlalchemy.schema.Table`\ 는 따라서 ::

        users = Table('users', metadata,
           Column('id', Integer, Sequence('user_id_seq'), primary_key=True),
           Column('name', String(50)),
           Column('fullname', String(50)),
           Column('password', String(12))
        )

    우리는 주로 파이썬 사용만을 위한 최소한의 구문과 더 엄격한 요구사항이 있는 특정
    백엔드 세트의 CREATE TABLE을 내보내기 위해 사용되는 구문의 차이점을 강조하기 위해
    위의 더 자세한 :class:`~.schema.Table` 구문을 분리해서 포함시켰다.

.. _coretutorial_insert_expressions_ko:

표현식 삽입
==================

가장 먼저 생성할 SQL 표현식은 :class:`~sqlalchemy.sql.expression.Insert` 구조로 INSERT 표현을 나타낸다.
이 표현식은 일반적으로 대상 테이블을 기준으로 생성된다. ::

    >>> ins = users.insert()

이 구조가 생성하는 SQL의 예시를 보기 위해 ``str()`` 함수를 사용한다 ::

    >>> str(ins)
    'INSERT INTO users (id, name, fullname) VALUES (:id, :name, :fullname)'

Notice above that the INSERT statement names every column in the ``users``
table. This can be limited by using the ``values()`` method, which establishes
the VALUES clause of the INSERT explicitly::

    >>> ins = users.insert().values(name='jack', fullname='Jack Jones')
    >>> str(ins)
    'INSERT INTO users (name, fullname) VALUES (:name, :fullname)'

Above, while the ``values`` method limited the VALUES clause to just two
columns, the actual data we placed in ``values`` didn't get rendered into the
string; instead we got named bind parameters. As it turns out, our data *is*
stored within our :class:`~sqlalchemy.sql.expression.Insert` construct, but it
typically only comes out when the statement is actually executed; since the
data consists of literal values, SQLAlchemy automatically generates bind
parameters for them. We can peek at this data for now by looking at the
compiled form of the statement::

    >>> ins.compile().params  # doctest: +SKIP
    {'fullname': 'Jack Jones', 'name': 'jack'}

Executing
=========

The interesting part of an :class:`~sqlalchemy.sql.expression.Insert` is
executing it. In this tutorial, we will generally focus on the most explicit
method of executing a SQL construct, and later touch upon some "shortcut" ways
to do it. The ``engine`` object we created is a repository for database
connections capable of issuing SQL to the database. To acquire a connection,
we use the ``connect()`` method::

    >>> conn = engine.connect()
    >>> conn
    <sqlalchemy.engine.base.Connection object at 0x...>

The :class:`~sqlalchemy.engine.Connection` object represents an actively
checked out DBAPI connection resource. Lets feed it our
:class:`~sqlalchemy.sql.expression.Insert` object and see what happens:

.. sourcecode:: pycon+sql

    >>> result = conn.execute(ins)
    {opensql}INSERT INTO users (name, fullname) VALUES (?, ?)
    ('jack', 'Jack Jones')
    COMMIT

So the INSERT statement was now issued to the database. Although we got
positional "qmark" bind parameters instead of "named" bind parameters in the
output. How come ? Because when executed, the
:class:`~sqlalchemy.engine.Connection` used the SQLite **dialect** to
help generate the statement; when we use the ``str()`` function, the statement
isn't aware of this dialect, and falls back onto a default which uses named
parameters. We can view this manually as follows:

.. sourcecode:: pycon+sql

    >>> ins.bind = engine
    >>> str(ins)
    'INSERT INTO users (name, fullname) VALUES (?, ?)'

What about the ``result`` variable we got when we called ``execute()`` ? As
the SQLAlchemy :class:`~sqlalchemy.engine.Connection` object references a
DBAPI connection, the result, known as a
:class:`~sqlalchemy.engine.ResultProxy` object, is analogous to the DBAPI
cursor object. In the case of an INSERT, we can get important information from
it, such as the primary key values which were generated from our statement
using :attr:`.ResultProxy.inserted_primary_key`:

.. sourcecode:: pycon+sql

    >>> result.inserted_primary_key
    [1]

The value of ``1`` was automatically generated by SQLite, but only because we
did not specify the ``id`` column in our
:class:`~sqlalchemy.sql.expression.Insert` statement; otherwise, our explicit
value would have been used. In either case, SQLAlchemy always knows how to get
at a newly generated primary key value, even though the method of generating
them is different across different databases; each database's
:class:`~sqlalchemy.engine.interfaces.Dialect` knows the specific steps needed to
determine the correct value (or values; note that
:attr:`.ResultProxy.inserted_primary_key`
returns a list so that it supports composite primary keys).    Methods here
range from using ``cursor.lastrowid``, to selecting from a database-specific
function, to using ``INSERT..RETURNING`` syntax; this all occurs transparently.

.. _execute_multiple:

Executing Multiple Statements
=============================

Our insert example above was intentionally a little drawn out to show some
various behaviors of expression language constructs. In the usual case, an
:class:`~sqlalchemy.sql.expression.Insert` statement is usually compiled
against the parameters sent to the ``execute()`` method on
:class:`~sqlalchemy.engine.Connection`, so that there's no need to use
the ``values`` keyword with :class:`~sqlalchemy.sql.expression.Insert`. Lets
create a generic :class:`~sqlalchemy.sql.expression.Insert` statement again
and use it in the "normal" way:

.. sourcecode:: pycon+sql

    >>> ins = users.insert()
    >>> conn.execute(ins, id=2, name='wendy', fullname='Wendy Williams')
    {opensql}INSERT INTO users (id, name, fullname) VALUES (?, ?, ?)
    (2, 'wendy', 'Wendy Williams')
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

Above, because we specified all three columns in the ``execute()`` method,
the compiled :class:`~.expression.Insert` included all three
columns. The :class:`~.expression.Insert` statement is compiled
at execution time based on the parameters we specified; if we specified fewer
parameters, the :class:`~.expression.Insert` would have fewer
entries in its VALUES clause.

To issue many inserts using DBAPI's ``executemany()`` method, we can send in a
list of dictionaries each containing a distinct set of parameters to be
inserted, as we do here to add some email addresses:

.. sourcecode:: pycon+sql

    >>> conn.execute(addresses.insert(), [
    ...    {'user_id': 1, 'email_address' : 'jack@yahoo.com'},
    ...    {'user_id': 1, 'email_address' : 'jack@msn.com'},
    ...    {'user_id': 2, 'email_address' : 'www@www.org'},
    ...    {'user_id': 2, 'email_address' : 'wendy@aol.com'},
    ... ])
    {opensql}INSERT INTO addresses (user_id, email_address) VALUES (?, ?)
    ((1, 'jack@yahoo.com'), (1, 'jack@msn.com'), (2, 'www@www.org'), (2, 'wendy@aol.com'))
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

Above, we again relied upon SQLite's automatic generation of primary key
identifiers for each ``addresses`` row.

When executing multiple sets of parameters, each dictionary must have the
**same** set of keys; i.e. you cant have fewer keys in some dictionaries than
others. This is because the :class:`~sqlalchemy.sql.expression.Insert`
statement is compiled against the **first** dictionary in the list, and it's
assumed that all subsequent argument dictionaries are compatible with that
statement.

The "executemany" style of invocation is available for each of the
:func:`.insert`, :func:`.update` and :func:`.delete` constructs.


.. _coretutorial_selecting:

Selecting
=========

We began with inserts just so that our test database had some data in it. The
more interesting part of the data is selecting it! We'll cover UPDATE and
DELETE statements later. The primary construct used to generate SELECT
statements is the :func:`.select` function:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import select
    >>> s = select([users])
    >>> result = conn.execute(s)
    {opensql}SELECT users.id, users.name, users.fullname
    FROM users
    ()

Above, we issued a basic :func:`.select` call, placing the ``users`` table
within the COLUMNS clause of the select, and then executing. SQLAlchemy
expanded the ``users`` table into the set of each of its columns, and also
generated a FROM clause for us. The result returned is again a
:class:`~sqlalchemy.engine.ResultProxy` object, which acts much like a
DBAPI cursor, including methods such as
:func:`~sqlalchemy.engine.ResultProxy.fetchone` and
:func:`~sqlalchemy.engine.ResultProxy.fetchall`. The easiest way to get
rows from it is to just iterate:

.. sourcecode:: pycon+sql

    >>> for row in result:
    ...     print(row)
    (1, u'jack', u'Jack Jones')
    (2, u'wendy', u'Wendy Williams')

Above, we see that printing each row produces a simple tuple-like result. We
have more options at accessing the data in each row. One very common way is
through dictionary access, using the string names of columns:

.. sourcecode:: pycon+sql

    {sql}>>> result = conn.execute(s)
    SELECT users.id, users.name, users.fullname
    FROM users
    ()

    {stop}>>> row = result.fetchone()
    >>> print("name:", row['name'], "; fullname:", row['fullname'])
    name: jack ; fullname: Jack Jones

Integer indexes work as well:

.. sourcecode:: pycon+sql

    >>> row = result.fetchone()
    >>> print("name:", row[1], "; fullname:", row[2])
    name: wendy ; fullname: Wendy Williams

But another way, whose usefulness will become apparent later on, is to use the
:class:`~sqlalchemy.schema.Column` objects directly as keys:

.. sourcecode:: pycon+sql

    {sql}>>> for row in conn.execute(s):
    ...     print("name:", row[users.c.name], "; fullname:", row[users.c.fullname])
    SELECT users.id, users.name, users.fullname
    FROM users
    ()
    {stop}name: jack ; fullname: Jack Jones
    name: wendy ; fullname: Wendy Williams

Result sets which have pending rows remaining should be explicitly closed
before discarding. While the cursor and connection resources referenced by the
:class:`~sqlalchemy.engine.ResultProxy` will be respectively closed and
returned to the connection pool when the object is garbage collected, it's
better to make it explicit as some database APIs are very picky about such
things:

.. sourcecode:: pycon+sql

    >>> result.close()

If we'd like to more carefully control the columns which are placed in the
COLUMNS clause of the select, we reference individual
:class:`~sqlalchemy.schema.Column` objects from our
:class:`~sqlalchemy.schema.Table`. These are available as named attributes off
the ``c`` attribute of the :class:`~sqlalchemy.schema.Table` object:

.. sourcecode:: pycon+sql

    >>> s = select([users.c.name, users.c.fullname])
    {sql}>>> result = conn.execute(s)
    SELECT users.name, users.fullname
    FROM users
    ()
    {stop}>>> for row in result:
    ...     print(row)
    (u'jack', u'Jack Jones')
    (u'wendy', u'Wendy Williams')

Lets observe something interesting about the FROM clause. Whereas the
generated statement contains two distinct sections, a "SELECT columns" part
and a "FROM table" part, our :func:`.select` construct only has a list
containing columns. How does this work ? Let's try putting *two* tables into
our :func:`.select` statement:

.. sourcecode:: pycon+sql

    {sql}>>> for row in conn.execute(select([users, addresses])):
    ...     print(row)
    SELECT users.id, users.name, users.fullname, addresses.id, addresses.user_id, addresses.email_address
    FROM users, addresses
    ()
    {stop}(1, u'jack', u'Jack Jones', 1, 1, u'jack@yahoo.com')
    (1, u'jack', u'Jack Jones', 2, 1, u'jack@msn.com')
    (1, u'jack', u'Jack Jones', 3, 2, u'www@www.org')
    (1, u'jack', u'Jack Jones', 4, 2, u'wendy@aol.com')
    (2, u'wendy', u'Wendy Williams', 1, 1, u'jack@yahoo.com')
    (2, u'wendy', u'Wendy Williams', 2, 1, u'jack@msn.com')
    (2, u'wendy', u'Wendy Williams', 3, 2, u'www@www.org')
    (2, u'wendy', u'Wendy Williams', 4, 2, u'wendy@aol.com')

It placed **both** tables into the FROM clause. But also, it made a real mess.
Those who are familiar with SQL joins know that this is a **Cartesian
product**; each row from the ``users`` table is produced against each row from
the ``addresses`` table. So to put some sanity into this statement, we need a
WHERE clause.  We do that using :meth:`.Select.where`:

.. sourcecode:: pycon+sql

    >>> s = select([users, addresses]).where(users.c.id == addresses.c.user_id)
    {sql}>>> for row in conn.execute(s):
    ...     print(row)
    SELECT users.id, users.name, users.fullname, addresses.id,
       addresses.user_id, addresses.email_address
    FROM users, addresses
    WHERE users.id = addresses.user_id
    ()
    {stop}(1, u'jack', u'Jack Jones', 1, 1, u'jack@yahoo.com')
    (1, u'jack', u'Jack Jones', 2, 1, u'jack@msn.com')
    (2, u'wendy', u'Wendy Williams', 3, 2, u'www@www.org')
    (2, u'wendy', u'Wendy Williams', 4, 2, u'wendy@aol.com')

So that looks a lot better, we added an expression to our :func:`.select`
which had the effect of adding ``WHERE users.id = addresses.user_id`` to our
statement, and our results were managed down so that the join of ``users`` and
``addresses`` rows made sense. But let's look at that expression? It's using
just a Python equality operator between two different
:class:`~sqlalchemy.schema.Column` objects. It should be clear that something
is up. Saying ``1 == 1`` produces ``True``, and ``1 == 2`` produces ``False``, not
a WHERE clause. So lets see exactly what that expression is doing:

.. sourcecode:: pycon+sql

    >>> users.c.id == addresses.c.user_id
    <sqlalchemy.sql.elements.BinaryExpression object at 0x...>

Wow, surprise ! This is neither a ``True`` nor a ``False``. Well what is it ?

.. sourcecode:: pycon+sql

    >>> str(users.c.id == addresses.c.user_id)
    'users.id = addresses.user_id'

As you can see, the ``==`` operator is producing an object that is very much
like the :class:`~.expression.Insert` and :func:`.select`
objects we've made so far, thanks to Python's ``__eq__()`` builtin; you call
``str()`` on it and it produces SQL. By now, one can see that everything we
are working with is ultimately the same type of object. SQLAlchemy terms the
base class of all of these expressions as :class:`~.expression.ColumnElement`.

Operators
=========

Since we've stumbled upon SQLAlchemy's operator paradigm, let's go through
some of its capabilities. We've seen how to equate two columns to each other:

.. sourcecode:: pycon+sql

    >>> print(users.c.id == addresses.c.user_id)
    users.id = addresses.user_id

If we use a literal value (a literal meaning, not a SQLAlchemy clause object),
we get a bind parameter:

.. sourcecode:: pycon+sql

    >>> print(users.c.id == 7)
    users.id = :id_1

The ``7`` literal is embedded the resulting
:class:`~.expression.ColumnElement`; we can use the same trick
we did with the :class:`~sqlalchemy.sql.expression.Insert` object to see it:

.. sourcecode:: pycon+sql

    >>> (users.c.id == 7).compile().params
    {u'id_1': 7}

Most Python operators, as it turns out, produce a SQL expression here, like
equals, not equals, etc.:

.. sourcecode:: pycon+sql

    >>> print(users.c.id != 7)
    users.id != :id_1

    >>> # None converts to IS NULL
    >>> print(users.c.name == None)
    users.name IS NULL

    >>> # reverse works too
    >>> print('fred' > users.c.name)
    users.name < :name_1

If we add two integer columns together, we get an addition expression:

.. sourcecode:: pycon+sql

    >>> print(users.c.id + addresses.c.id)
    users.id + addresses.id

Interestingly, the type of the :class:`~sqlalchemy.schema.Column` is important!
If we use ``+`` with two string based columns (recall we put types like
:class:`~sqlalchemy.types.Integer` and :class:`~sqlalchemy.types.String` on
our :class:`~sqlalchemy.schema.Column` objects at the beginning), we get
something different:

.. sourcecode:: pycon+sql

    >>> print(users.c.name + users.c.fullname)
    users.name || users.fullname

Where ``||`` is the string concatenation operator used on most databases. But
not all of them. MySQL users, fear not:

.. sourcecode:: pycon+sql

    >>> print((users.c.name + users.c.fullname).
    ...      compile(bind=create_engine('mysql://'))) # doctest: +SKIP
    concat(users.name, users.fullname)

The above illustrates the SQL that's generated for an
:class:`~sqlalchemy.engine.Engine` that's connected to a MySQL database;
the ``||`` operator now compiles as MySQL's ``concat()`` function.

If you have come across an operator which really isn't available, you can
always use the :meth:`.Operators.op` method; this generates whatever operator you need:

.. sourcecode:: pycon+sql

    >>> print(users.c.name.op('tiddlywinks')('foo'))
    users.name tiddlywinks :name_1

This function can also be used to make bitwise operators explicit. For example::

    somecolumn.op('&')(0xff)

is a bitwise AND of the value in ``somecolumn``.

When using :meth:`.Operators.op`, the return type of the expression may be important,
especialy when the operator is used in an expression that will be sent as a result
column.   For this case, be sure to make the type explicit, if not what's
normally expected, using :func:`.type_coerce`::

    from sqlalchemy import type_coerce
    expr = type_coerce(somecolumn.op('-%>')('foo'), MySpecialType())
    stmt = select([expr])


For boolean operators, use the :meth:`.Operators.bool_op` method, which
will ensure that the return type of the expression is handled as boolean::

    somecolumn.bool_op('-->')('some value')

.. versionadded:: 1.2.0b3  Added the :meth:`.Operators.bool_op` method.

Operator Customization
----------------------

While :meth:`.Operators.op` is handy to get at a custom operator in a hurry,
the Core supports fundamental customization and extension of the operator system at
the type level.   The behavior of existing operators can be modified on a per-type
basis, and new operations can be defined which become available for all column
expressions that are part of that particular type.  See the section :ref:`types_operators`
for a description.



Conjunctions
============


We'd like to show off some of our operators inside of :func:`.select`
constructs. But we need to lump them together a little more, so let's first
introduce some conjunctions. Conjunctions are those little words like AND and
OR that put things together. We'll also hit upon NOT. :func:`.and_`, :func:`.or_`,
and :func:`.not_` can work
from the corresponding functions SQLAlchemy provides (notice we also throw in
a :meth:`~.ColumnOperators.like`):

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import and_, or_, not_
    >>> print(and_(
    ...         users.c.name.like('j%'),
    ...         users.c.id == addresses.c.user_id,
    ...         or_(
    ...              addresses.c.email_address == 'wendy@aol.com',
    ...              addresses.c.email_address == 'jack@yahoo.com'
    ...         ),
    ...         not_(users.c.id > 5)
    ...       )
    ...  )
    users.name LIKE :name_1 AND users.id = addresses.user_id AND
    (addresses.email_address = :email_address_1
       OR addresses.email_address = :email_address_2)
    AND users.id <= :id_1

And you can also use the re-jiggered bitwise AND, OR and NOT operators,
although because of Python operator precedence you have to watch your
parenthesis:

.. sourcecode:: pycon+sql

    >>> print(users.c.name.like('j%') & (users.c.id == addresses.c.user_id) &
    ...     (
    ...       (addresses.c.email_address == 'wendy@aol.com') | \
    ...       (addresses.c.email_address == 'jack@yahoo.com')
    ...     ) \
    ...     & ~(users.c.id>5)
    ... )
    users.name LIKE :name_1 AND users.id = addresses.user_id AND
    (addresses.email_address = :email_address_1
        OR addresses.email_address = :email_address_2)
    AND users.id <= :id_1

So with all of this vocabulary, let's select all users who have an email
address at AOL or MSN, whose name starts with a letter between "m" and "z",
and we'll also generate a column containing their full name combined with
their email address. We will add two new constructs to this statement,
:meth:`~.ColumnOperators.between` and :meth:`~.ColumnElement.label`.
:meth:`~.ColumnOperators.between` produces a BETWEEN clause, and
:meth:`~.ColumnElement.label` is used in a column expression to produce labels using the ``AS``
keyword; it's recommended when selecting from expressions that otherwise would
not have a name:

.. sourcecode:: pycon+sql

    >>> s = select([(users.c.fullname +
    ...               ", " + addresses.c.email_address).
    ...                label('title')]).\
    ...        where(
    ...           and_(
    ...               users.c.id == addresses.c.user_id,
    ...               users.c.name.between('m', 'z'),
    ...               or_(
    ...                  addresses.c.email_address.like('%@aol.com'),
    ...                  addresses.c.email_address.like('%@msn.com')
    ...               )
    ...           )
    ...        )
    >>> conn.execute(s).fetchall()
    SELECT users.fullname || ? || addresses.email_address AS title
    FROM users, addresses
    WHERE users.id = addresses.user_id AND users.name BETWEEN ? AND ? AND
    (addresses.email_address LIKE ? OR addresses.email_address LIKE ?)
    (', ', 'm', 'z', '%@aol.com', '%@msn.com')
    [(u'Wendy Williams, wendy@aol.com',)]

Once again, SQLAlchemy figured out the FROM clause for our statement. In fact
it will determine the FROM clause based on all of its other bits; the columns
clause, the where clause, and also some other elements which we haven't
covered yet, which include ORDER BY, GROUP BY, and HAVING.

A shortcut to using :func:`.and_` is to chain together multiple
:meth:`~.Select.where` clauses.   The above can also be written as:

.. sourcecode:: pycon+sql

    >>> s = select([(users.c.fullname +
    ...               ", " + addresses.c.email_address).
    ...                label('title')]).\
    ...        where(users.c.id == addresses.c.user_id).\
    ...        where(users.c.name.between('m', 'z')).\
    ...        where(
    ...               or_(
    ...                  addresses.c.email_address.like('%@aol.com'),
    ...                  addresses.c.email_address.like('%@msn.com')
    ...               )
    ...        )
    >>> conn.execute(s).fetchall()
    SELECT users.fullname || ? || addresses.email_address AS title
    FROM users, addresses
    WHERE users.id = addresses.user_id AND users.name BETWEEN ? AND ? AND
    (addresses.email_address LIKE ? OR addresses.email_address LIKE ?)
    (', ', 'm', 'z', '%@aol.com', '%@msn.com')
    [(u'Wendy Williams, wendy@aol.com',)]

The way that we can build up a :func:`.select` construct through successive
method calls is called :term:`method chaining`.

.. _sqlexpression_text:

Using Textual SQL
=================

Our last example really became a handful to type. Going from what one
understands to be a textual SQL expression into a Python construct which
groups components together in a programmatic style can be hard. That's why
SQLAlchemy lets you just use strings, for those cases when the SQL
is already known and there isn't a strong need for the statement to support
dynamic features.  The :func:`~.expression.text` construct is used
to compose a textual statement that is passed to the database mostly
unchanged.  Below, we create a :func:`~.expression.text` object and execute it:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import text
    >>> s = text(
    ...     "SELECT users.fullname || ', ' || addresses.email_address AS title "
    ...         "FROM users, addresses "
    ...         "WHERE users.id = addresses.user_id "
    ...         "AND users.name BETWEEN :x AND :y "
    ...         "AND (addresses.email_address LIKE :e1 "
    ...             "OR addresses.email_address LIKE :e2)")
    {sql}>>> conn.execute(s, x='m', y='z', e1='%@aol.com', e2='%@msn.com').fetchall()
    SELECT users.fullname || ', ' || addresses.email_address AS title
    FROM users, addresses
    WHERE users.id = addresses.user_id AND users.name BETWEEN ? AND ? AND
    (addresses.email_address LIKE ? OR addresses.email_address LIKE ?)
    ('m', 'z', '%@aol.com', '%@msn.com')
    {stop}[(u'Wendy Williams, wendy@aol.com',)]

Above, we can see that bound parameters are specified in
:func:`~.expression.text` using the named colon format; this format is
consistent regardless of database backend.  To send values in for the
parameters, we passed them into the :meth:`~.Connection.execute` method
as additional arguments.

Specifying Bound Parameter Behaviors
------------------------------------

The :func:`~.expression.text` construct supports pre-established bound values
using the :meth:`.TextClause.bindparams` method::

    stmt = text("SELECT * FROM users WHERE users.name BETWEEN :x AND :y")
    stmt = stmt.bindparams(x="m", y="z")

The parameters can also be explicitly typed::

    stmt = stmt.bindparams(bindparam("x", String), bindparam("y", String))
    result = conn.execute(stmt, {"x": "m", "y": "z"})

Typing for bound parameters is necessary when the type requires Python-side
or special SQL-side processing provided by the datatype.

.. seealso::

    :meth:`.TextClause.bindparams` - full method description

.. _sqlexpression_text_columns:

Specifying Result-Column Behaviors
----------------------------------

We may also specify information about the result columns using the
:meth:`.TextClause.columns` method; this method can be used to specify
the return types, based on name::

    stmt = stmt.columns(id=Integer, name=String)

or it can be passed full column expressions positionally, either typed
or untyped.  In this case it's a good idea to list out the columns
explicitly within our textual SQL, since the correlation of our column
expressions to the SQL will be done positionally::

    stmt = text("SELECT id, name FROM users")
    stmt = stmt.columns(users.c.id, users.c.name)

When we call the :meth:`.TextClause.columns` method, we get back a
:class:`.TextAsFrom` object that supports the full suite of
:attr:`.TextAsFrom.c` and other "selectable" operations::

    j = stmt.join(addresses, stmt.c.id == addresses.c.user_id)

    new_stmt = select([stmt.c.id, addresses.c.id]).\
        select_from(j).where(stmt.c.name == 'x')

The positional form of :meth:`.TextClause.columns` is particularly useful
when relating textual SQL to existing Core or ORM models, because we can use
column expressions directly without worrying about name conflicts or other issues with the
result column names in the textual SQL:

.. sourcecode:: pycon+sql

    >>> stmt = text("SELECT users.id, addresses.id, users.id, "
    ...     "users.name, addresses.email_address AS email "
    ...     "FROM users JOIN addresses ON users.id=addresses.user_id "
    ...     "WHERE users.id = 1").columns(
    ...        users.c.id,
    ...        addresses.c.id,
    ...        addresses.c.user_id,
    ...        users.c.name,
    ...        addresses.c.email_address
    ...     )
    {sql}>>> result = conn.execute(stmt)
    SELECT users.id, addresses.id, users.id, users.name,
        addresses.email_address AS email
    FROM users JOIN addresses ON users.id=addresses.user_id WHERE users.id = 1
    ()
    {stop}

Above, there's three columns in the result that are named "id", but since
we've associated these with column expressions positionally, the names aren't an issue
when the result-columns are fetched using the actual column object as a key.
Fetching the ``email_address`` column would be::

    >>> row = result.fetchone()
    >>> row[addresses.c.email_address]
    'jack@yahoo.com'

If on the other hand we used a string column key, the usual rules of name-
based matching still apply, and we'd get an ambiguous column error for
the ``id`` value::

    >>> row["id"]
    Traceback (most recent call last):
    ...
    InvalidRequestError: Ambiguous column name 'id' in result set column descriptions

It's important to note that while accessing columns from a result set using
:class:`.Column` objects may seem unusual, it is in fact the only system
used by the ORM, which occurs transparently beneath the facade of the
:class:`~.orm.query.Query` object; in this way, the :meth:`.TextClause.columns` method
is typically very applicable to textual statements to be used in an ORM
context.   The example at :ref:`orm_tutorial_literal_sql` illustrates
a simple usage.

.. versionadded:: 1.1

    The :meth:`.TextClause.columns` method now accepts column expressions
    which will be matched positionally to a plain text SQL result set,
    eliminating the need for column names to match or even be unique in the
    SQL statement when matching table metadata or ORM models to textual SQL.

.. seealso::

    :meth:`.TextClause.columns` - full method description

    :ref:`orm_tutorial_literal_sql` - integrating ORM-level queries with
    :func:`.text`


Using text() fragments inside bigger statements
-----------------------------------------------

:func:`~.expression.text` can also be used to produce fragments of SQL
that can be freely within a
:func:`~.expression.select` object, which accepts :func:`~.expression.text`
objects as an argument for most of its builder functions.
Below, we combine the usage of :func:`~.expression.text` within a
:func:`.select` object.  The :func:`~.expression.select` construct provides the "geometry"
of the statement, and the :func:`~.expression.text` construct provides the
textual content within this form.  We can build a statement without the
need to refer to any pre-established :class:`.Table` metadata:

.. sourcecode:: pycon+sql

    >>> s = select([
    ...        text("users.fullname || ', ' || addresses.email_address AS title")
    ...     ]).\
    ...         where(
    ...             and_(
    ...                 text("users.id = addresses.user_id"),
    ...                 text("users.name BETWEEN 'm' AND 'z'"),
    ...                 text(
    ...                     "(addresses.email_address LIKE :x "
    ...                     "OR addresses.email_address LIKE :y)")
    ...             )
    ...         ).select_from(text('users, addresses'))
    {sql}>>> conn.execute(s, x='%@aol.com', y='%@msn.com').fetchall()
    SELECT users.fullname || ', ' || addresses.email_address AS title
    FROM users, addresses
    WHERE users.id = addresses.user_id AND users.name BETWEEN 'm' AND 'z'
    AND (addresses.email_address LIKE ? OR addresses.email_address LIKE ?)
    ('%@aol.com', '%@msn.com')
    {stop}[(u'Wendy Williams, wendy@aol.com',)]

.. versionchanged:: 1.0.0
   The :func:`.select` construct emits warnings when string SQL
   fragments are coerced to :func:`.text`, and :func:`.text` should
   be used explicitly.  See :ref:`migration_2992` for background.



.. _sqlexpression_literal_column:

Using More Specific Text with :func:`.table`, :func:`.literal_column`, and :func:`.column`
-------------------------------------------------------------------------------------------

We can move our level of structure back in the other direction too,
by using :func:`~.expression.column`, :func:`~.expression.literal_column`,
and :func:`~.expression.table` for some of the
key elements of our statement.   Using these constructs, we can get
some more expression capabilities than if we used :func:`~.expression.text`
directly, as they provide to the Core more information about how the strings
they store are to be used, but still without the need to get into full
:class:`.Table` based metadata.  Below, we also specify the :class:`.String`
datatype for two of the key :func:`~.expression.literal_column` objects,
so that the string-specific concatenation operator becomes available.
We also use :func:`~.expression.literal_column` in order to use table-qualified
expressions, e.g. ``users.fullname``, that will be rendered as is;
using :func:`~.expression.column` implies an individual column name that may
be quoted:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy import select, and_, text, String
    >>> from sqlalchemy.sql import table, literal_column
    >>> s = select([
    ...    literal_column("users.fullname", String) +
    ...    ', ' +
    ...    literal_column("addresses.email_address").label("title")
    ... ]).\
    ...    where(
    ...        and_(
    ...            literal_column("users.id") == literal_column("addresses.user_id"),
    ...            text("users.name BETWEEN 'm' AND 'z'"),
    ...            text(
    ...                "(addresses.email_address LIKE :x OR "
    ...                "addresses.email_address LIKE :y)")
    ...        )
    ...    ).select_from(table('users')).select_from(table('addresses'))

    {sql}>>> conn.execute(s, x='%@aol.com', y='%@msn.com').fetchall()
    SELECT users.fullname || ? || addresses.email_address AS anon_1
    FROM users, addresses
    WHERE users.id = addresses.user_id
    AND users.name BETWEEN 'm' AND 'z'
    AND (addresses.email_address LIKE ? OR addresses.email_address LIKE ?)
    (', ', '%@aol.com', '%@msn.com')
    {stop}[(u'Wendy Williams, wendy@aol.com',)]

Ordering or Grouping by a Label
-------------------------------

One place where we sometimes want to use a string as a shortcut is when
our statement has some labeled column element that we want to refer to in
a place such as the "ORDER BY" or "GROUP BY" clause; other candidates include
fields within an "OVER" or "DISTINCT" clause.  If we have such a label
in our :func:`.select` construct, we can refer to it directly by passing the
string straight into :meth:`.select.order_by` or :meth:`.select.group_by`,
among others.  This will refer to the named label and also prevent the
expression from being rendered twice:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy import func
    >>> stmt = select([
    ...         addresses.c.user_id,
    ...         func.count(addresses.c.id).label('num_addresses')]).\
    ...         order_by("num_addresses")

    {sql}>>> conn.execute(stmt).fetchall()
    SELECT addresses.user_id, count(addresses.id) AS num_addresses
    FROM addresses ORDER BY num_addresses
    ()
    {stop}[(2, 4)]

We can use modifiers like :func:`.asc` or :func:`.desc` by passing the string
name:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy import func, desc
    >>> stmt = select([
    ...         addresses.c.user_id,
    ...         func.count(addresses.c.id).label('num_addresses')]).\
    ...         order_by(desc("num_addresses"))

    {sql}>>> conn.execute(stmt).fetchall()
    SELECT addresses.user_id, count(addresses.id) AS num_addresses
    FROM addresses ORDER BY num_addresses DESC
    ()
    {stop}[(2, 4)]

Note that the string feature here is very much tailored to when we have
already used the :meth:`~.ColumnElement.label` method to create a
specifically-named label.  In other cases, we always want to refer to the
:class:`.ColumnElement` object directly so that the expression system can
make the most effective choices for rendering.  Below, we illustrate how using
the :class:`.ColumnElement` eliminates ambiguity when we want to order
by a column name that appears more than once:

.. sourcecode:: pycon+sql

    >>> u1a, u1b = users.alias(), users.alias()
    >>> stmt = select([u1a, u1b]).\
    ...             where(u1a.c.name > u1b.c.name).\
    ...             order_by(u1a.c.name)  # using "name" here would be ambiguous

    {sql}>>> conn.execute(stmt).fetchall()
    SELECT users_1.id, users_1.name, users_1.fullname, users_2.id,
    users_2.name, users_2.fullname
    FROM users AS users_1, users AS users_2
    WHERE users_1.name > users_2.name ORDER BY users_1.name
    ()
    {stop}[(2, u'wendy', u'Wendy Williams', 1, u'jack', u'Jack Jones')]




Using Aliases
=============

The alias in SQL corresponds to a "renamed" version of a table or SELECT
statement, which occurs anytime you say "SELECT .. FROM sometable AS
someothername". The ``AS`` creates a new name for the table. Aliases are a key
construct as they allow any table or subquery to be referenced by a unique
name. In the case of a table, this allows the same table to be named in the
FROM clause multiple times. In the case of a SELECT statement, it provides a
parent name for the columns represented by the statement, allowing them to be
referenced relative to this name.

In SQLAlchemy, any :class:`.Table`, :func:`.select` construct, or
other selectable can be turned into an alias using the :meth:`.FromClause.alias`
method, which produces a :class:`.Alias` construct.  As an example, suppose we know that our user ``jack`` has two
particular email addresses. How can we locate jack based on the combination of those two
addresses?   To accomplish this, we'd use a join to the ``addresses`` table,
once for each address.   We create two :class:`.Alias` constructs against
``addresses``, and then use them both within a :func:`.select` construct:

.. sourcecode:: pycon+sql

    >>> a1 = addresses.alias()
    >>> a2 = addresses.alias()
    >>> s = select([users]).\
    ...        where(and_(
    ...            users.c.id == a1.c.user_id,
    ...            users.c.id == a2.c.user_id,
    ...            a1.c.email_address == 'jack@msn.com',
    ...            a2.c.email_address == 'jack@yahoo.com'
    ...        ))
    {sql}>>> conn.execute(s).fetchall()
    SELECT users.id, users.name, users.fullname
    FROM users, addresses AS addresses_1, addresses AS addresses_2
    WHERE users.id = addresses_1.user_id
        AND users.id = addresses_2.user_id
        AND addresses_1.email_address = ?
        AND addresses_2.email_address = ?
    ('jack@msn.com', 'jack@yahoo.com')
    {stop}[(1, u'jack', u'Jack Jones')]

Note that the :class:`.Alias` construct generated the names ``addresses_1`` and
``addresses_2`` in the final SQL result.  The generation of these names is determined
by the position of the construct within the statement.   If we created a query using
only the second ``a2`` alias, the name would come out as ``addresses_1``.  The
generation of the names is also *deterministic*, meaning the same SQLAlchemy
statement construct will produce the identical SQL string each time it is
rendered for a particular dialect.

Since on the outside, we refer to the alias using the :class:`.Alias` construct
itself, we don't need to be concerned about the generated name.  However, for
the purposes of debugging, it can be specified by passing a string name
to the :meth:`.FromClause.alias` method::

    >>> a1 = addresses.alias('a1')

Aliases can of course be used for anything which you can SELECT from,
including SELECT statements themselves. We can self-join the ``users`` table
back to the :func:`.select` we've created by making an alias of the entire
statement. The ``correlate(None)`` directive is to avoid SQLAlchemy's attempt
to "correlate" the inner ``users`` table with the outer one:

.. sourcecode:: pycon+sql

    >>> a1 = s.correlate(None).alias()
    >>> s = select([users.c.name]).where(users.c.id == a1.c.id)
    {sql}>>> conn.execute(s).fetchall()
    SELECT users.name
    FROM users,
        (SELECT users.id AS id, users.name AS name, users.fullname AS fullname
            FROM users, addresses AS addresses_1, addresses AS addresses_2
            WHERE users.id = addresses_1.user_id AND users.id = addresses_2.user_id
            AND addresses_1.email_address = ?
            AND addresses_2.email_address = ?) AS anon_1
    WHERE users.id = anon_1.id
    ('jack@msn.com', 'jack@yahoo.com')
    {stop}[(u'jack',)]

Using Joins
===========

We're halfway along to being able to construct any SELECT expression. The next
cornerstone of the SELECT is the JOIN expression. We've already been doing
joins in our examples, by just placing two tables in either the columns clause
or the where clause of the :func:`.select` construct. But if we want to make a
real "JOIN" or "OUTERJOIN" construct, we use the :meth:`~.FromClause.join` and
:meth:`~.FromClause.outerjoin` methods, most commonly accessed from the left table in the
join:

.. sourcecode:: pycon+sql

    >>> print(users.join(addresses))
    users JOIN addresses ON users.id = addresses.user_id

The alert reader will see more surprises; SQLAlchemy figured out how to JOIN
the two tables ! The ON condition of the join, as it's called, was
automatically generated based on the :class:`~sqlalchemy.schema.ForeignKey`
object which we placed on the ``addresses`` table way at the beginning of this
tutorial. Already the ``join()`` construct is looking like a much better way
to join tables.

Of course you can join on whatever expression you want, such as if we want to
join on all users who use the same name in their email address as their
username:

.. sourcecode:: pycon+sql

    >>> print(users.join(addresses,
    ...                 addresses.c.email_address.like(users.c.name + '%')
    ...             )
    ...  )
    users JOIN addresses ON addresses.email_address LIKE users.name || :name_1

When we create a :func:`.select` construct, SQLAlchemy looks around at the
tables we've mentioned and then places them in the FROM clause of the
statement. When we use JOINs however, we know what FROM clause we want, so
here we make use of the :meth:`~.Select.select_from` method:

.. sourcecode:: pycon+sql

    >>> s = select([users.c.fullname]).select_from(
    ...    users.join(addresses,
    ...             addresses.c.email_address.like(users.c.name + '%'))
    ...    )
    {sql}>>> conn.execute(s).fetchall()
    SELECT users.fullname
    FROM users JOIN addresses ON addresses.email_address LIKE users.name || ?
    ('%',)
    {stop}[(u'Jack Jones',), (u'Jack Jones',), (u'Wendy Williams',)]

The :meth:`~.FromClause.outerjoin` method creates ``LEFT OUTER JOIN`` constructs,
and is used in the same way as :meth:`~.FromClause.join`:

.. sourcecode:: pycon+sql

    >>> s = select([users.c.fullname]).select_from(users.outerjoin(addresses))
    >>> print(s)
    SELECT users.fullname
        FROM users
        LEFT OUTER JOIN addresses ON users.id = addresses.user_id

That's the output ``outerjoin()`` produces, unless, of course, you're stuck in
a gig using Oracle prior to version 9, and you've set up your engine (which
would be using ``OracleDialect``) to use Oracle-specific SQL:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.dialects.oracle import dialect as OracleDialect
    >>> print(s.compile(dialect=OracleDialect(use_ansi=False)))
    SELECT users.fullname
    FROM users, addresses
    WHERE users.id = addresses.user_id(+)

If you don't know what that SQL means, don't worry ! The secret tribe of
Oracle DBAs don't want their black magic being found out ;).

.. seealso::

    :func:`.expression.join`

    :func:`.expression.outerjoin`

    :class:`.Join`

Everything Else
===============

The concepts of creating SQL expressions have been introduced. What's left are
more variants of the same themes. So now we'll catalog the rest of the
important things we'll need to know.

.. _coretutorial_bind_param:

Bind Parameter Objects
----------------------

Throughout all these examples, SQLAlchemy is busy creating bind parameters
wherever literal expressions occur. You can also specify your own bind
parameters with your own names, and use the same statement repeatedly.
The :func:`.bindparam` construct is used to produce a bound parameter
with a given name.  While SQLAlchemy always refers to bound parameters by
name on the API side, the
database dialect converts to the appropriate named or positional style
at execution time, as here where it converts to positional for SQLite:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import bindparam
    >>> s = users.select(users.c.name == bindparam('username'))
    {sql}>>> conn.execute(s, username='wendy').fetchall()
    SELECT users.id, users.name, users.fullname
    FROM users
    WHERE users.name = ?
    ('wendy',)
    {stop}[(2, u'wendy', u'Wendy Williams')]

Another important aspect of :func:`.bindparam` is that it may be assigned a
type. The type of the bind parameter will determine its behavior within
expressions and also how the data bound to it is processed before being sent
off to the database:

.. sourcecode:: pycon+sql

    >>> s = users.select(users.c.name.like(bindparam('username', type_=String) + text("'%'")))
    {sql}>>> conn.execute(s, username='wendy').fetchall()
    SELECT users.id, users.name, users.fullname
    FROM users
    WHERE users.name LIKE ? || '%'
    ('wendy',)
    {stop}[(2, u'wendy', u'Wendy Williams')]


:func:`.bindparam` constructs of the same name can also be used multiple times, where only a
single named value is needed in the execute parameters:

.. sourcecode:: pycon+sql

    >>> s = select([users, addresses]).\
    ...     where(
    ...        or_(
    ...          users.c.name.like(
    ...                 bindparam('name', type_=String) + text("'%'")),
    ...          addresses.c.email_address.like(
    ...                 bindparam('name', type_=String) + text("'@%'"))
    ...        )
    ...     ).\
    ...     select_from(users.outerjoin(addresses)).\
    ...     order_by(addresses.c.id)
    {sql}>>> conn.execute(s, name='jack').fetchall()
    SELECT users.id, users.name, users.fullname, addresses.id,
        addresses.user_id, addresses.email_address
    FROM users LEFT OUTER JOIN addresses ON users.id = addresses.user_id
    WHERE users.name LIKE ? || '%' OR addresses.email_address LIKE ? || '@%'
    ORDER BY addresses.id
    ('jack', 'jack')
    {stop}[(1, u'jack', u'Jack Jones', 1, 1, u'jack@yahoo.com'), (1, u'jack', u'Jack Jones', 2, 1, u'jack@msn.com')]

.. seealso::

    :func:`.bindparam`

Functions
---------

SQL functions are created using the :data:`~.expression.func` keyword, which
generates functions using attribute access:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import func
    >>> print(func.now())
    now()

    >>> print(func.concat('x', 'y'))
    concat(:concat_1, :concat_2)

By "generates", we mean that **any** SQL function is created based on the word
you choose::

    >>> print(func.xyz_my_goofy_function())
    xyz_my_goofy_function()

Certain function names are known by SQLAlchemy, allowing special behavioral
rules to be applied. Some for example are "ANSI" functions, which mean they
don't get the parenthesis added after them, such as CURRENT_TIMESTAMP:

.. sourcecode:: pycon+sql

    >>> print(func.current_timestamp())
    CURRENT_TIMESTAMP

Functions are most typically used in the columns clause of a select statement,
and can also be labeled as well as given a type. Labeling a function is
recommended so that the result can be targeted in a result row based on a
string name, and assigning it a type is required when you need result-set
processing to occur, such as for Unicode conversion and date conversions.
Below, we use the result function ``scalar()`` to just read the first column
of the first row and then close the result; the label, even though present, is
not important in this case:

.. sourcecode:: pycon+sql

    >>> conn.execute(
    ...     select([
    ...            func.max(addresses.c.email_address, type_=String).
    ...                label('maxemail')
    ...           ])
    ...     ).scalar()
    {opensql}SELECT max(addresses.email_address) AS maxemail
    FROM addresses
    ()
    {stop}u'www@www.org'

Databases such as PostgreSQL and Oracle which support functions that return
whole result sets can be assembled into selectable units, which can be used in
statements. Such as, a database function ``calculate()`` which takes the
parameters ``x`` and ``y``, and returns three columns which we'd like to name
``q``, ``z`` and ``r``, we can construct using "lexical" column objects as
well as bind parameters:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import column
    >>> calculate = select([column('q'), column('z'), column('r')]).\
    ...        select_from(
    ...             func.calculate(
    ...                    bindparam('x'),
    ...                    bindparam('y')
    ...                )
    ...             )
    >>> calc = calculate.alias()
    >>> print(select([users]).where(users.c.id > calc.c.z))
    SELECT users.id, users.name, users.fullname
    FROM users, (SELECT q, z, r
    FROM calculate(:x, :y)) AS anon_1
    WHERE users.id > anon_1.z

If we wanted to use our ``calculate`` statement twice with different bind
parameters, the :func:`~sqlalchemy.sql.expression.ClauseElement.unique_params`
function will create copies for us, and mark the bind parameters as "unique"
so that conflicting names are isolated. Note we also make two separate aliases
of our selectable:

.. sourcecode:: pycon+sql

    >>> calc1 = calculate.alias('c1').unique_params(x=17, y=45)
    >>> calc2 = calculate.alias('c2').unique_params(x=5, y=12)
    >>> s = select([users]).\
    ...         where(users.c.id.between(calc1.c.z, calc2.c.z))
    >>> print(s)
    SELECT users.id, users.name, users.fullname
    FROM users,
        (SELECT q, z, r FROM calculate(:x_1, :y_1)) AS c1,
        (SELECT q, z, r FROM calculate(:x_2, :y_2)) AS c2
    WHERE users.id BETWEEN c1.z AND c2.z

    >>> s.compile().params # doctest: +SKIP
    {u'x_2': 5, u'y_2': 12, u'y_1': 45, u'x_1': 17}

.. seealso::

    :data:`.func`

.. _window_functions:

Window Functions
----------------

Any :class:`.FunctionElement`, including functions generated by
:data:`~.expression.func`, can be turned into a "window function", that is an
OVER clause, using the :meth:`.FunctionElement.over` method::

    >>> s = select([
    ...         users.c.id,
    ...         func.row_number().over(order_by=users.c.name)
    ...     ])
    >>> print(s)
    SELECT users.id, row_number() OVER (ORDER BY users.name) AS anon_1
    FROM users

:meth:`.FunctionElement.over` also supports range specification using
either the :paramref:`.expression.over.rows` or
:paramref:`.expression.over.range` parameters::

    >>> s = select([
    ...         users.c.id,
    ...         func.row_number().over(
    ...                 order_by=users.c.name,
    ...                 rows=(-2, None))
    ...     ])
    >>> print(s)
    SELECT users.id, row_number() OVER
    (ORDER BY users.name ROWS BETWEEN :param_1 PRECEDING AND UNBOUNDED FOLLOWING) AS anon_1
    FROM users

:paramref:`.expression.over.rows` and :paramref:`.expression.over.range` each
accept a two-tuple which contains a combination of negative and positive
integers for ranges, zero to indicate "CURRENT ROW" and ``None`` to
indicate "UNBOUNDED".  See the examples at :func:`.over` for more detail.

.. versionadded:: 1.1 support for "rows" and "range" specification for
   window functions

.. seealso::

    :func:`.over`

    :meth:`.FunctionElement.over`

Unions and Other Set Operations
-------------------------------

Unions come in two flavors, UNION and UNION ALL, which are available via
module level functions :func:`~.expression.union` and
:func:`~.expression.union_all`:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import union
    >>> u = union(
    ...     addresses.select().
    ...             where(addresses.c.email_address == 'foo@bar.com'),
    ...    addresses.select().
    ...             where(addresses.c.email_address.like('%@yahoo.com')),
    ... ).order_by(addresses.c.email_address)

    {sql}>>> conn.execute(u).fetchall()
    SELECT addresses.id, addresses.user_id, addresses.email_address
    FROM addresses
    WHERE addresses.email_address = ?
    UNION
    SELECT addresses.id, addresses.user_id, addresses.email_address
    FROM addresses
    WHERE addresses.email_address LIKE ? ORDER BY addresses.email_address
    ('foo@bar.com', '%@yahoo.com')
    {stop}[(1, 1, u'jack@yahoo.com')]

Also available, though not supported on all databases, are
:func:`~.expression.intersect`,
:func:`~.expression.intersect_all`,
:func:`~.expression.except_`, and :func:`~.expression.except_all`:

.. sourcecode:: pycon+sql

    >>> from sqlalchemy.sql import except_
    >>> u = except_(
    ...    addresses.select().
    ...             where(addresses.c.email_address.like('%@%.com')),
    ...    addresses.select().
    ...             where(addresses.c.email_address.like('%@msn.com'))
    ... )

    {sql}>>> conn.execute(u).fetchall()
    SELECT addresses.id, addresses.user_id, addresses.email_address
    FROM addresses
    WHERE addresses.email_address LIKE ?
    EXCEPT
    SELECT addresses.id, addresses.user_id, addresses.email_address
    FROM addresses
    WHERE addresses.email_address LIKE ?
    ('%@%.com', '%@msn.com')
    {stop}[(1, 1, u'jack@yahoo.com'), (4, 2, u'wendy@aol.com')]

A common issue with so-called "compound" selectables arises due to the fact
that they nest with parenthesis. SQLite in particular doesn't like a statement
that starts with parenthesis. So when nesting a "compound" inside a
"compound", it's often necessary to apply ``.alias().select()`` to the first
element of the outermost compound, if that element is also a compound. For
example, to nest a "union" and a "select" inside of "except\_", SQLite will
want the "union" to be stated as a subquery:

.. sourcecode:: pycon+sql

    >>> u = except_(
    ...    union(
    ...         addresses.select().
    ...             where(addresses.c.email_address.like('%@yahoo.com')),
    ...         addresses.select().
    ...             where(addresses.c.email_address.like('%@msn.com'))
    ...     ).alias().select(),   # apply subquery here
    ...    addresses.select(addresses.c.email_address.like('%@msn.com'))
    ... )
    {sql}>>> conn.execute(u).fetchall()
    SELECT anon_1.id, anon_1.user_id, anon_1.email_address
    FROM (SELECT addresses.id AS id, addresses.user_id AS user_id,
        addresses.email_address AS email_address
        FROM addresses
        WHERE addresses.email_address LIKE ?
        UNION
        SELECT addresses.id AS id,
            addresses.user_id AS user_id,
            addresses.email_address AS email_address
        FROM addresses
        WHERE addresses.email_address LIKE ?) AS anon_1
    EXCEPT
    SELECT addresses.id, addresses.user_id, addresses.email_address
    FROM addresses
    WHERE addresses.email_address LIKE ?
    ('%@yahoo.com', '%@msn.com', '%@msn.com')
    {stop}[(1, 1, u'jack@yahoo.com')]

.. seealso::

    :func:`.union`

    :func:`.union_all`

    :func:`.intersect`

    :func:`.intersect_all`

    :func:`.except_`

    :func:`.except_all`

.. _scalar_selects:

Scalar Selects
--------------

A scalar select is a SELECT that returns exactly one row and one
column.  It can then be used as a column expression.  A scalar select
is often a :term:`correlated subquery`, which relies upon the enclosing
SELECT statement in order to acquire at least one of its FROM clauses.

The :func:`.select` construct can be modified to act as a
column expression by calling either the :meth:`~.SelectBase.as_scalar`
or :meth:`~.SelectBase.label` method:

.. sourcecode:: pycon+sql

    >>> stmt = select([func.count(addresses.c.id)]).\
    ...             where(users.c.id == addresses.c.user_id).\
    ...             as_scalar()

The above construct is now a :class:`~.expression.ScalarSelect` object,
and is no longer part of the :class:`~.expression.FromClause` hierarchy;
it instead is within the :class:`~.expression.ColumnElement` family of
expression constructs.  We can place this construct the same as any
other column within another :func:`.select`:

.. sourcecode:: pycon+sql

    >>> conn.execute(select([users.c.name, stmt])).fetchall()
    {opensql}SELECT users.name, (SELECT count(addresses.id) AS count_1
    FROM addresses
    WHERE users.id = addresses.user_id) AS anon_1
    FROM users
    ()
    {stop}[(u'jack', 2), (u'wendy', 2)]

To apply a non-anonymous column name to our scalar select, we create
it using :meth:`.SelectBase.label` instead:

.. sourcecode:: pycon+sql

    >>> stmt = select([func.count(addresses.c.id)]).\
    ...             where(users.c.id == addresses.c.user_id).\
    ...             label("address_count")
    >>> conn.execute(select([users.c.name, stmt])).fetchall()
    {opensql}SELECT users.name, (SELECT count(addresses.id) AS count_1
    FROM addresses
    WHERE users.id = addresses.user_id) AS address_count
    FROM users
    ()
    {stop}[(u'jack', 2), (u'wendy', 2)]

.. seealso::

    :meth:`.Select.as_scalar`

    :meth:`.Select.label`

.. _correlated_subqueries:

Correlated Subqueries
---------------------

Notice in the examples on :ref:`scalar_selects`, the FROM clause of each embedded
select did not contain the ``users`` table in its FROM clause. This is because
SQLAlchemy automatically :term:`correlates` embedded FROM objects to that
of an enclosing query, if present, and if the inner SELECT statement would
still have at least one FROM clause of its own.  For example:

.. sourcecode:: pycon+sql

    >>> stmt = select([addresses.c.user_id]).\
    ...             where(addresses.c.user_id == users.c.id).\
    ...             where(addresses.c.email_address == 'jack@yahoo.com')
    >>> enclosing_stmt = select([users.c.name]).where(users.c.id == stmt)
    >>> conn.execute(enclosing_stmt).fetchall()
    {opensql}SELECT users.name
    FROM users
    WHERE users.id = (SELECT addresses.user_id
        FROM addresses
        WHERE addresses.user_id = users.id
        AND addresses.email_address = ?)
    ('jack@yahoo.com',)
    {stop}[(u'jack',)]

Auto-correlation will usually do what's expected, however it can also be controlled.
For example, if we wanted a statement to correlate only to the ``addresses`` table
but not the ``users`` table, even if both were present in the enclosing SELECT,
we use the :meth:`~.Select.correlate` method to specify those FROM clauses that
may be correlated:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.id]).\
    ...             where(users.c.id == addresses.c.user_id).\
    ...             where(users.c.name == 'jack').\
    ...             correlate(addresses)
    >>> enclosing_stmt = select(
    ...         [users.c.name, addresses.c.email_address]).\
    ...     select_from(users.join(addresses)).\
    ...     where(users.c.id == stmt)
    >>> conn.execute(enclosing_stmt).fetchall()
    {opensql}SELECT users.name, addresses.email_address
     FROM users JOIN addresses ON users.id = addresses.user_id
     WHERE users.id = (SELECT users.id
     FROM users
     WHERE users.id = addresses.user_id AND users.name = ?)
     ('jack',)
     {stop}[(u'jack', u'jack@yahoo.com'), (u'jack', u'jack@msn.com')]

To entirely disable a statement from correlating, we can pass ``None``
as the argument:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.id]).\
    ...             where(users.c.name == 'wendy').\
    ...             correlate(None)
    >>> enclosing_stmt = select([users.c.name]).\
    ...     where(users.c.id == stmt)
    >>> conn.execute(enclosing_stmt).fetchall()
    {opensql}SELECT users.name
     FROM users
     WHERE users.id = (SELECT users.id
      FROM users
      WHERE users.name = ?)
    ('wendy',)
    {stop}[(u'wendy',)]

We can also control correlation via exclusion, using the :meth:`.Select.correlate_except`
method.   Such as, we can write our SELECT for the ``users`` table
by telling it to correlate all FROM clauses except for ``users``:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.id]).\
    ...             where(users.c.id == addresses.c.user_id).\
    ...             where(users.c.name == 'jack').\
    ...             correlate_except(users)
    >>> enclosing_stmt = select(
    ...         [users.c.name, addresses.c.email_address]).\
    ...     select_from(users.join(addresses)).\
    ...     where(users.c.id == stmt)
    >>> conn.execute(enclosing_stmt).fetchall()
    {opensql}SELECT users.name, addresses.email_address
     FROM users JOIN addresses ON users.id = addresses.user_id
     WHERE users.id = (SELECT users.id
     FROM users
     WHERE users.id = addresses.user_id AND users.name = ?)
     ('jack',)
     {stop}[(u'jack', u'jack@yahoo.com'), (u'jack', u'jack@msn.com')]

.. _lateral_selects:

LATERAL correlation
^^^^^^^^^^^^^^^^^^^

LATERAL correlation is a special sub-category of SQL correlation which
allows a selectable unit to refer to another selectable unit within a
single FROM clause.  This is an extremely special use case which, while
part of the SQL standard, is only known to be supported by recent
versions of PostgreSQL.

Normally, if a SELECT statement refers to
``table1 JOIN (some SELECT) AS subquery`` in its FROM clause, the subquery
on the right side may not refer to the "table1" expression from the left side;
correlation may only refer to a table that is part of another SELECT that
entirely encloses this SELECT.  The LATERAL keyword allows us to turn this
behavior around, allowing an expression such as:

.. sourcecode:: sql

    SELECT people.people_id, people.age, people.name
    FROM people JOIN LATERAL (SELECT books.book_id AS book_id
    FROM books WHERE books.owner_id = people.people_id)
    AS book_subq ON true

Where above, the right side of the JOIN contains a subquery that refers not
just to the "books" table but also the "people" table, correlating
to the left side of the JOIN.   SQLAlchemy Core supports a statement
like the above using the :meth:`.Select.lateral` method as follows::

    >>> from sqlalchemy import table, column, select, true
    >>> people = table('people', column('people_id'), column('age'), column('name'))
    >>> books = table('books', column('book_id'), column('owner_id'))
    >>> subq = select([books.c.book_id]).\
    ...      where(books.c.owner_id == people.c.people_id).lateral("book_subq")
    >>> print(select([people]).select_from(people.join(subq, true())))
    SELECT people.people_id, people.age, people.name
    FROM people JOIN LATERAL (SELECT books.book_id AS book_id
    FROM books WHERE books.owner_id = people.people_id)
    AS book_subq ON true

Above, we can see that the :meth:`.Select.lateral` method acts a lot like
the :meth:`.Select.alias` method, including that we can specify an optional
name.  However the construct is the :class:`.Lateral` construct instead of
an :class:`.Alias` which provides for the LATERAL keyword as well as special
instructions to allow correlation from inside the FROM clause of the
enclosing statement.

The :meth:`.Select.lateral` method interacts normally with the
:meth:`.Select.correlate` and :meth:`.Select.correlate_except` methods, except
that the correlation rules also apply to any other tables present in the
enclosing statement's FROM clause.   Correlation is "automatic" to these
tables by default, is explicit if the table is specified to
:meth:`.Select.correlate`, and is explicit to all tables except those
specified to :meth:`.Select.correlate_except`.


.. versionadded:: 1.1

    Support for the LATERAL keyword and lateral correlation.

.. seealso::

    :class:`.Lateral`

    :meth:`.Select.lateral`


Ordering, Grouping, Limiting, Offset...ing...
---------------------------------------------

Ordering is done by passing column expressions to the
:meth:`~.SelectBase.order_by` method:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name]).order_by(users.c.name)
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT users.name
    FROM users ORDER BY users.name
    ()
    {stop}[(u'jack',), (u'wendy',)]

Ascending or descending can be controlled using the :meth:`~.ColumnElement.asc`
and :meth:`~.ColumnElement.desc` modifiers:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name]).order_by(users.c.name.desc())
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT users.name
    FROM users ORDER BY users.name DESC
    ()
    {stop}[(u'wendy',), (u'jack',)]

Grouping refers to the GROUP BY clause, and is usually used in conjunction
with aggregate functions to establish groups of rows to be aggregated.
This is provided via the :meth:`~.SelectBase.group_by` method:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name, func.count(addresses.c.id)]).\
    ...             select_from(users.join(addresses)).\
    ...             group_by(users.c.name)
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT users.name, count(addresses.id) AS count_1
    FROM users JOIN addresses
        ON users.id = addresses.user_id
    GROUP BY users.name
    ()
    {stop}[(u'jack', 2), (u'wendy', 2)]

HAVING can be used to filter results on an aggregate value, after GROUP BY has
been applied.  It's available here via the :meth:`~.Select.having`
method:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name, func.count(addresses.c.id)]).\
    ...             select_from(users.join(addresses)).\
    ...             group_by(users.c.name).\
    ...             having(func.length(users.c.name) > 4)
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT users.name, count(addresses.id) AS count_1
    FROM users JOIN addresses
        ON users.id = addresses.user_id
    GROUP BY users.name
    HAVING length(users.name) > ?
    (4,)
    {stop}[(u'wendy', 2)]

A common system of dealing with duplicates in composed SELECT statements
is the DISTINCT modifier.  A simple DISTINCT clause can be added using the
:meth:`.Select.distinct` method:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name]).\
    ...             where(addresses.c.email_address.
    ...                    contains(users.c.name)).\
    ...             distinct()
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT DISTINCT users.name
    FROM users, addresses
    WHERE (addresses.email_address LIKE '%' || users.name || '%')
    ()
    {stop}[(u'jack',), (u'wendy',)]

Most database backends support a system of limiting how many rows
are returned, and the majority also feature a means of starting to return
rows after a given "offset".   While common backends like PostgreSQL,
MySQL and SQLite support LIMIT and OFFSET keywords, other backends
need to refer to more esoteric features such as "window functions"
and row ids to achieve the same effect.  The :meth:`~.Select.limit`
and :meth:`~.Select.offset` methods provide an easy abstraction
into the current backend's methodology:

.. sourcecode:: pycon+sql

    >>> stmt = select([users.c.name, addresses.c.email_address]).\
    ...             select_from(users.join(addresses)).\
    ...             limit(1).offset(1)
    >>> conn.execute(stmt).fetchall()
    {opensql}SELECT users.name, addresses.email_address
    FROM users JOIN addresses ON users.id = addresses.user_id
     LIMIT ? OFFSET ?
    (1, 1)
    {stop}[(u'jack', u'jack@msn.com')]


.. _inserts_and_updates:

Inserts, Updates and Deletes
============================

We've seen :meth:`~.TableClause.insert` demonstrated
earlier in this tutorial.   Where :meth:`~.TableClause.insert`
produces INSERT, the :meth:`~.TableClause.update`
method produces UPDATE.  Both of these constructs feature
a method called :meth:`~.ValuesBase.values` which specifies
the VALUES or SET clause of the statement.

The :meth:`~.ValuesBase.values` method accommodates any column expression
as a value:

.. sourcecode:: pycon+sql

    >>> stmt = users.update().\
    ...             values(fullname="Fullname: " + users.c.name)
    >>> conn.execute(stmt)
    {opensql}UPDATE users SET fullname=(? || users.name)
    ('Fullname: ',)
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

When using :meth:`~.TableClause.insert` or :meth:`~.TableClause.update`
in an "execute many" context, we may also want to specify named
bound parameters which we can refer to in the argument list.
The two constructs will automatically generate bound placeholders
for any column names passed in the dictionaries sent to
:meth:`~.Connection.execute` at execution time.  However, if we
wish to use explicitly targeted named parameters with composed expressions,
we need to use the :func:`~.expression.bindparam` construct.
When using :func:`~.expression.bindparam` with
:meth:`~.TableClause.insert` or :meth:`~.TableClause.update`,
the names of the table's columns themselves are reserved for the
"automatic" generation of bind names.  We can combine the usage
of implicitly available bind names and explicitly named parameters
as in the example below:

.. sourcecode:: pycon+sql

    >>> stmt = users.insert().\
    ...         values(name=bindparam('_name') + " .. name")
    >>> conn.execute(stmt, [
    ...        {'id':4, '_name':'name1'},
    ...        {'id':5, '_name':'name2'},
    ...        {'id':6, '_name':'name3'},
    ...     ])
    {opensql}INSERT INTO users (id, name) VALUES (?, (? || ?))
    ((4, 'name1', ' .. name'), (5, 'name2', ' .. name'), (6, 'name3', ' .. name'))
    COMMIT
    <sqlalchemy.engine.result.ResultProxy object at 0x...>

An UPDATE statement is emitted using the :meth:`~.TableClause.update` construct.  This
works much like an INSERT, except there is an additional WHERE clause
that can be specified:

.. sourcecode:: pycon+sql

    >>> stmt = users.update().\
    ...             where(users.c.name == 'jack').\
    ...             values(name='ed')

    >>> conn.execute(stmt)
    {opensql}UPDATE users SET name=? WHERE users.name = ?
    ('ed', 'jack')
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

When using :meth:`~.TableClause.update` in an "executemany" context,
we may wish to also use explicitly named bound parameters in the
WHERE clause.  Again, :func:`~.expression.bindparam` is the construct
used to achieve this:

.. sourcecode:: pycon+sql

    >>> stmt = users.update().\
    ...             where(users.c.name == bindparam('oldname')).\
    ...             values(name=bindparam('newname'))
    >>> conn.execute(stmt, [
    ...     {'oldname':'jack', 'newname':'ed'},
    ...     {'oldname':'wendy', 'newname':'mary'},
    ...     {'oldname':'jim', 'newname':'jake'},
    ...     ])
    {opensql}UPDATE users SET name=? WHERE users.name = ?
    (('ed', 'jack'), ('mary', 'wendy'), ('jake', 'jim'))
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>


Correlated Updates
------------------

A correlated update lets you update a table using selection from another
table, or the same table:

.. sourcecode:: pycon+sql

    >>> stmt = select([addresses.c.email_address]).\
    ...             where(addresses.c.user_id == users.c.id).\
    ...             limit(1)
    >>> conn.execute(users.update().values(fullname=stmt))
    {opensql}UPDATE users SET fullname=(SELECT addresses.email_address
        FROM addresses
        WHERE addresses.user_id = users.id
        LIMIT ? OFFSET ?)
    (1, 0)
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

.. _multi_table_updates:

Multiple Table Updates
----------------------

.. versionadded:: 0.7.4

The PostgreSQL, Microsoft SQL Server, and MySQL backends all support UPDATE statements
that refer to multiple tables.   For PG and MSSQL, this is the "UPDATE FROM" syntax,
which updates one table at a time, but can reference additional tables in an additional
"FROM" clause that can then be referenced in the WHERE clause directly.   On MySQL,
multiple tables can be embedded into a single UPDATE statement separated by a comma.
The SQLAlchemy :func:`.update` construct supports both of these modes
implicitly, by specifying multiple tables in the WHERE clause::

    stmt = users.update().\
            values(name='ed wood').\
            where(users.c.id == addresses.c.id).\
            where(addresses.c.email_address.startswith('ed%'))
    conn.execute(stmt)

The resulting SQL from the above statement would render as::

    UPDATE users SET name=:name FROM addresses
    WHERE users.id = addresses.id AND
    addresses.email_address LIKE :email_address_1 || '%'

When using MySQL, columns from each table can be assigned to in the
SET clause directly, using the dictionary form passed to :meth:`.Update.values`::

    stmt = users.update().\
            values({
                users.c.name:'ed wood',
                addresses.c.email_address:'ed.wood@foo.com'
            }).\
            where(users.c.id == addresses.c.id).\
            where(addresses.c.email_address.startswith('ed%'))

The tables are referenced explicitly in the SET clause::

    UPDATE users, addresses SET addresses.email_address=%s,
            users.name=%s WHERE users.id = addresses.id
            AND addresses.email_address LIKE concat(%s, '%')

SQLAlchemy doesn't do anything special when these constructs are used on
a non-supporting database.  The ``UPDATE FROM`` syntax generates by default
when multiple tables are present, and the statement will be rejected
by the database if this syntax is not supported.

.. _updates_order_parameters:

Parameter-Ordered Updates
-------------------------

The default behavior of the :func:`.update` construct when rendering the SET
clauses is to render them using the column ordering given in the
originating :class:`.Table` object.
This is an important behavior, since it means that the rendering of a
particular UPDATE statement with particular columns
will be rendered the same each time, which has an impact on query caching systems
that rely on the form of the statement, either client side or server side.
Since the parameters themselves are passed to the :meth:`.Update.values`
method as Python dictionary keys, there is no other fixed ordering
available.

However in some cases, the order of parameters rendered in the SET clause of an
UPDATE statement can be significant.  The main example of this is when using
MySQL and providing updates to column values based on that of other
column values.  The end result of the following statement::

    UPDATE some_table SET x = y + 10, y = 20

Will have a different result than::

    UPDATE some_table SET y = 20, x = y + 10

This because on MySQL, the individual SET clauses are fully evaluated on
a per-value basis, as opposed to on a per-row basis, and as each SET clause
is evaluated, the values embedded in the row are changing.

To suit this specific use case, the
:paramref:`~sqlalchemy.sql.expression.update.preserve_parameter_order`
flag may be used.  When using this flag, we supply a **Python list of 2-tuples**
as the argument to the :meth:`.Update.values` method::

    stmt = some_table.update(preserve_parameter_order=True).\
        values([(some_table.c.y, 20), (some_table.c.x, some_table.c.y + 10)])

The list of 2-tuples is essentially the same structure as a Python dictionary
except it is ordered.  Using the above form, we are assured that the
"y" column's SET clause will render first, then the "x" column's SET clause.

.. versionadded:: 1.0.10 Added support for explicit ordering of UPDATE
   parameters using the :paramref:`~sqlalchemy.sql.expression.update.preserve_parameter_order` flag.


.. _deletes:

Deletes
-------

Finally, a delete.  This is accomplished easily enough using the
:meth:`~.TableClause.delete` construct:

.. sourcecode:: pycon+sql

    >>> conn.execute(addresses.delete())
    {opensql}DELETE FROM addresses
    ()
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

    >>> conn.execute(users.delete().where(users.c.name > 'm'))
    {opensql}DELETE FROM users WHERE users.name > ?
    ('m',)
    COMMIT
    {stop}<sqlalchemy.engine.result.ResultProxy object at 0x...>

Matched Row Counts
------------------

Both of :meth:`~.TableClause.update` and
:meth:`~.TableClause.delete` are associated with *matched row counts*.  This is a
number indicating the number of rows that were matched by the WHERE clause.
Note that by "matched", this includes rows where no UPDATE actually took place.
The value is available as :attr:`~.ResultProxy.rowcount`:

.. sourcecode:: pycon+sql

    >>> result = conn.execute(users.delete())
    {opensql}DELETE FROM users
    ()
    COMMIT
    {stop}>>> result.rowcount
    1

Further Reference
=================

Expression Language Reference: :ref:`expression_api_toplevel`

Database Metadata Reference: :ref:`metadata_toplevel`

Engine Reference: :doc:`/core/engines`

Connection Reference: :ref:`connections_toplevel`

Types Reference: :ref:`types_toplevel`


