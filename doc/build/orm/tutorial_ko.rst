.. _ormtutorial_toplevel:

==========================
객체 관계 튜토리얼
==========================

SQLAlchemy 객체 관계형 맵퍼는 사용자가 정의한 클레스를 테이터베이스 테이블에, 그 클래스(객체)의
인스턴스를 대응하는 테이블의 행에 결합시키는 메서드를 제공한다. SQLAlchemy는 :term:`unit of work`\ 라고 불리는
객체와 그와 관련된 행 사이의 모든 변화를 명확하게 동기화시키는 시스템을 포함하고 있을 뿐만 아니라
데이터베이스 쿼리를 사용자가 정의한 클래스와 클래스 사이에서 정의된 관계로 표현할 수 있게 하는
시스템도 포함하고 있다.

ORM은 ORM이 구축된 바탕이 되는 SQLAlchemy 표현 언어와는 반대이다. :ref:`sqlexpression_toplevel`\ 에 소개된
SQL 표현 언어는 의견 없이 직접적으로 관계형 데이터 베이스의 원시적인 구조 나타내는 시스템을 보여주는 반면
ORM은 높은 레벨의 추상화된 사용 패턴을 보여주며 그 자신이 표현 언어의 응용된 사용법의 예시가 된다.

ORM과 표현 언어의 사용 패턴 사이에 겹치는 부분이 존재하지만 유사점은 처음에 나타나는 것에 비해 훨씬
추상적이다. 하나는 드러나지 않는 스토리지 모델에서 명박하게 추적되고 리프레시 되는 사용자가 정의한 :term:`domain model`\ 의 관점에서 데이터의 내용과 구조에
접근한다. 다른 하나는 데이터베이스에 의해 개별적으로 사용되는 메세지로 명시적으로 구성되는 리터럴 스키마와
SQL 표현의 관점에서 접근한다.

성공적인 어플리케이션은 ORM만 사용해서 구성될 수 있다.
수준이 높은 상황의 경우 ORM으로 구성된 어플리케이션은 종종 특정 데이터베이스와의 상호작용이
필요한 부분에서 직접적으로 표현 언어를 사용할 수 있다.

아래의 튜토리얼은 doctest 형식이며 ``>>>`` 라인은 파이썬 커맨드 프롬프트에 입력할 수 있다는
것을 의미하며 그 아래의 텍스트는 예상되는 리턴 값을 의미한다.

Version Check
=============

최소한 **1.2 버전**\ 의 SQLAlchemy를 사용하고 있는지 빠르게 확인해보자::

    >>> import sqlalchemy
    >>> sqlalchemy.__version__ # doctest:+SKIP
    1.2.0

Connecting
==========

이 튜토리얼을 위해서 우리는 in-memory-only SQLite 데이터베이스를 사용할 것이다. 연결을 위해서
:func:`~sqlalchemy.create_engine`\ 를 사용한다::

    >>> from sqlalchemy import create_engine
    >>> engine = create_engine('sqlite:///:memory:', echo=True)

``echo`` 플래그는 SQLAlchemy 로깅을 설정하기 위한 단축어이며 로깅은 파이썬의 표준 ``logging`` 모듈을
통해서 이루어진다. 활성화가 되면 우리는 생성된 모든 SQL을 확인할 수 있다. 만약 이 튜토리얼을 하면서
출력이 적게 나오기를 바란다며 ``False``\ 로 설정하면 된다. 이 튜토리얼은 팝업 창 뒤에서 SQL을
구성할 것이기 우리가 방해받는 일은 없을 것이다; 어떤 것이 생성되었는지 확인하려면 "SQL" 링크를 누르기만
하면 된다.

:func:`.create_engine`\ 의 리턴 값은 :class:`.Engine`\ 의 인스턴스이며, 이것은 사용중인
:term:`DBAPI`\ 와 데이터베이스의 세부사항을 처리하는 :term:`dialect`\ 를 통해 적응된 데이터베이스
의 핵심 인터페이스를 나타낸다. 이 경우 SQL dialect가 파이썬 내장 ``sqlite3`` 모듈에 대한 명령을
해석할 것이다.

.. sidebar:: Lazy Connecting

    최초로 :func:`.create_engine`\ 에 의해 리턴 되었을 때, :class:`.Engine`\ 는
    실제로 데이터베이스에 연결을 시도하지 않는다; 연결은 데이터베이스에 대한 작업을 수행하도록
    최초로 요청받았을 때 이루어 진다.

:meth:`.Engine.execute` 또는 :meth:`.Engine.connect`\ 가 최초로 호출되면,
:class:`.Engine`\ 은 데이터베이스에 대한 실제 :term:`DBAPI` 연결을 실시하고 그 다음에
SQL을 내보내는 데 사용된다. ORM을 사용할 때, 한번 생성이 됐으면 우리는 일반적으로
:class:`.Engine`\ 를 직접적으로 사용하지는 않는다. 대신에 ORM에 의해 뒤에서 사용된다.
이 부분은 곧 확인할 것이다.

.. seealso::

    :ref:`database_urls` - :func:`.create_engine`\ 로 여러 종류의 데이터베이스에
    연결하는 예를 포함하고 있으며 다른 정보에 대한 링크도 포함하고 있다.

Declare a Mapping
=================

ORM을 사용할 때, 데이터베이스 테이블을 구성하고 그 테이블에 매핑될 우리의 클래스를 정의함으로써
설정 프로세스를 시작한다. 현재의 SQLAlchemy에서, 이 두 작업은 :ref:`declarative_toplevel`\ 로 알려진
시스템을 사용해 보통 함께 수행된다. 이 시스템은 매핑될 실제 데이터베이스 테이블을 구성하는 명령어를
포함하는 클래스를 생성할 수 있게 해준다.

Declarative system을 사용하여 매핑된 클래스는 base와 연관된 테이블과와 클래스의 카탈로그를 유지하는 base 클래스로
정의되며 이 클래스는 **declarative base class**\ 로 알려져 있다. 어플리케이션은 일반적으로
임포트 되는 모듈에 있는 base의 인스턴스 하나를 가지게 된다. base class 는 :func:`.declarative_base` 함수를
사용해서 아래처럼 생성한다::

    >>> from sqlalchemy.ext.declarative import declarative_base

    >>> Base = declarative_base()

이제 "base"를 가지게 되었으므로, 어떤 수의 매핑된 클래스도 정의할 수 있다. 우리는 ``users``\ 라고
불리리는 xpdlqmf 하나로 시작할 것이며 이 테이블은 우리의 어플리케이션을 사용하는 엔드 유저의 기록을 저장할 것이다.
``User``\ 라고 불리는 새로운 클래스는 이 테이블을 매핑할 클래스가 될 것이다. 이 클래스 안에서 우리는
매핑할 테이블에 대한 세부 사항을 정의할 것이다. 우선 테이블 이름과 컬럼의 이름과 데이터 타입을
정의한다::

    >>> from sqlalchemy import Column, Integer, String
    >>> class User(Base):
    ...     __tablename__ = 'users'
    ...
    ...     id = Column(Integer, primary_key=True)
    ...     name = Column(String)
    ...     fullname = Column(String)
    ...     password = Column(String)
    ...
    ...     def __repr__(self):
    ...        return "<User(name='%s', fullname='%s', password='%s')>" % (
    ...                             self.name, self.fullname, self.password)

.. sidebar:: Tip

    ``User`` 클래스가 ``__repr__()`` 메서드를 정의하지만,
    이 부분은 **선택적인** 부분이다; 형식이 잘 갖춰진 ``User`` 객체를 보여주기
    위해서 이 튜토리얼에서 구현한 것이다.

Declarative를 사용하는 클래스는 최소한 ``__tablename__`` 속성과 primary key [#]_\ 의
부분이 되는 하나 이상의 :class:`.Column`\ 이 있어야 한다. SQLAlchemy는 클래스가
참조하는 테이블에 대한 어떠한 가정도 하지 않으며 이름이나 데이터 타입, 제약 사항에 대한 내장된 관례도
없다. 하지만 그렇다고 표준 문안을 요구하는 것은 아니다; 대신 helper 함수와 mixin 클래스들을 이용해서
자신만의 자동화된 관례를 만들 수 있다. :ref:`declarative_mixins`\ 를 참고하라.

클래스가 구성이 될 때, Declarative는 모든 :class:`.Column` 객채를 :term:`descriptors`\ 로
알려진 특별 파이썬 접근자로 대체한다. 매핑된 "instrumented" 클래스는 우리에게 SQL 컨텍스트에서 테이블을 참조하고
데이터베이스의 컬럼의 값을 불러오고 유지할 수 있는 방법을 제공한다.

매핑 프로세스가 우리의 클래스에 하는 작업 외에, 클래스는 대부분 일반 파이썬 클래스로 남아있어서
이 클래스에서 우리의 어플리케이션에서 필요한 일반적인 메서드와 속성을 정의할 수 있다.

.. [#] primary key가 왜 요구되는지에 대해서는 :ref:`faq_mapper_primary_key`\ 를
       참고하라.


Create a Schema
===============

Declarative systme을 통해 생성된 ``User`` 클래스로, 우리는 테이블에 대한 정보 :term:`table metadata`\ 를
정의할 수 있다. 특정한 테이블에 대한 정보를 나타내기 위해 SQLAlchemy에 의해 사용된 객체는 :class:`.Table` 객체라
불린다. 그리고 여기서는 Declarative가 하나를 만들었다. 우리는 이 오브젝트를 ``__table__`` 속성을
통해 확인할 수 있다::

    >>> User.__table__ # doctest: +NORMALIZE_WHITESPACE
    Table('users', MetaData(bind=None),
                Column('id', Integer(), table=<users>, primary_key=True, nullable=False),
                Column('name', String(), table=<users>),
                Column('fullname', String(), table=<users>),
                Column('password', String(), table=<users>), schema=None)

.. sidebar:: Classical Mappings

    매우 추천되기는 하지만 Declarative system은 SQLAlchemy의 ORM을 사용하기 위해서
    요구되는 것은 아니다. Declarative 외에, 일반 파이썬 클래스도 :func:`.mapper` 함수를 직접
    사용해서 :class:`.Table`\ 로 맵핑할 수 있다; 덜 일반적으로 사용되는 이 방법은 :ref:`classical_mapping`\ 에
    설명되어 있다.

클래스를 선언했을 때, Declarative는 일단 클래스 선언이 완료되면 추가적인 작동을 수행하기 위해
파이썬 메타클래스를 사용한다; 이 단계 에서, 세부 사항에 따라 :class:`.Table` 객체를
생성하고 :class:`.Mapper` 객체를 생성함으로써 둘을 결합시킨다. 이 객체는 뒷단에 있는 객체이며 우리가
직접 처리할 필요는 없다 (필요한 경우 매핑에 대한 많은 정보를 제공해주기는 한다).

:class:`.Table` 객체는 :class:`.MetaData`\ 라는 더 큰 집합의 구성원이다.
Declarative를 사용할 때, 이 객체는 declarative base class의 ``.metadata`` 속성을 이용해
사용할 수 있다.

:class:`.MetaData`\ 는 제한된 스키마 생성 커맨드 세트를 데이터베이스로 보내기 위한 기능을 포함하고
있는 :term:`registry`\ 다. 현재 우리의 SQLite 데이터베이스가 실제로 ``users`` 테이블을 가지고 있지 않기
때문에 아직 존재하지 않는 모든 테이블에 대해 CREATE TABLE 명령을 데이터베이스에 전달하기 위해 :class:`.MetaData`\ 를
사용할 것이다.아래에서, 우리는 :meth:`.MetaData.create_all` 메서드를 호출해서, 우리의 :class:`.Engine`\ 에
데이터 베이스 연결 소스로서 전달했다. 특별 커맨드가 ``user`` 테이블의 존재를 확인하기 위해서 먼저 발행되고
그다음 실제 ``CREATE TABLE`` 명령이 전달되는 것을 보게 될 것이다:

.. sourcecode:: python+sql

    >>> Base.metadata.create_all(engine)
    SELECT ...
    PRAGMA table_info("users")
    ()
    CREATE TABLE users (
        id INTEGER NOT NULL, name VARCHAR,
        fullname VARCHAR,
        password VARCHAR,
        PRIMARY KEY (id)
    )
    ()
    COMMIT

.. topic:: Minimal Table Descriptions vs. Full Descriptions

    CREATE TABLE 신택스에 익숙한 사용자는 VARCHAR 컬럼이 길이제한 없이 생성된 것을
    알아차렸을 것이다. SQLite나 PostegreSQL에서, 이 것은 유효한 데이터 타입지만, 다른 것에서는
    그렇지 않다. 따라서 이 튜토리얼을 그런 데이터베이스에서 실행하는 경우 SQLAlchemy를 통해서
    CREATE TABLE을 발행하고 싶을 때 "길이"를 :class:`~sqlalchemy.types.String` 타입에
    아래처럼 제공해야 한다::

        Column(String(50))

    :class:`~sqlalchemy.types.String`\ 의 length 필드와, :class:`~sqlalchemy.types.Integer',
    :class:`~sqlalchemy.types.Numeric` 등에서 이용 가능한 precision/scale 필드는 테이블을
    생성할 때를 제외하고는 SQLAlchemy에 의해 참조되지 않는다.

    추가적으로, Firebird와 Oracle은 새로운 primary key 식별자를 생성하기 위해서 시퀀스를 요구하는데
    SQLAlchemy는 지시 없이 이런 것들을 가정하거나 생성하지 않는다. 시퀀스를 위해서는
    :class:`~sqlalchemy.schema.Sequence` 구조를 사용해야 한다::

        from sqlalchemy import Sequence
        Column(Integer, Sequence('user_id_seq'), primary_key=True)

    declarative 매핑을 통해 생성된 전체, :class:`~sqlalchemy.schema.Table`\ 는
    아래와 같다::

        class User(Base):
            __tablename__ = 'users'
            id = Column(Integer, Sequence('user_id_seq'), primary_key=True)
            name = Column(String(50))
            fullname = Column(String(50))
            password = Column(String(12))

            def __repr__(self):
                return "<User(name='%s', fullname='%s', password='%s')>" % (
                                        self.name, self.fullname, self.password)

    주로 파이썬 내에서의 사용만을 위해 고안된
    최소한의 구조와 더 엄격한 요구사항이 있는 특정한 백엔드 세트에서의 CREATE TABLE 명령문을
    위해서 사용되는 구조의 차이점을 강조하기 위해 상세한 테이블 정의를 따로 포함시켰다.

Create an Instance of the Mapped Class
======================================

매핑이 끝나면, ``User`` 객체를 생성하고 검사해보자::

    >>> ed_user = User(name='ed', fullname='Ed Jones', password='edspassword')
    >>> ed_user.name
    'ed'
    >>> ed_user.password
    'edspassword'
    >>> str(ed_user.id)
    'None'


.. sidebar:: the ``__init__()`` method

    Declarative system을 이용해 정의된 ``User`` 클래스는 컨스트럭터(예, ``__init__()`` 메서드)를
    제공받는데 이 컨스트럭터는 자동적으로 우리가 매핑해놓은 컬럼과 일치하는 키워드명을 받는다.
    우리의 클래스에서 명시적인 ``__init__()``\ 메서드를 자유롭게 정의할 수도 있다.
    이 메서드는 Declarative에 의해 제공된 기본 메서드를 덮어쓰게 된다.

우리가 컨스트럭터에서 지정하지 않았더라도 접근하면 ``id`` 속성으로 ``None`` 값을 생성한다
(파이썬이 일반적으로 정의되지 않은 속성에 대해 ``AttributionError``\ 를 발생시키는 것과
반대된다). SQLAlchemy의 :term:`instrumentation`\ 는 일반적으로 컬럼에 매핑된 속성에 처음
접근했을 때 이 기본 값을 생성한다. 실제로 값을 할당한 속성은
데이터베이스에 보내질 최종적인 INSERT 명령문에서 사용될 수 있도록 계측 시스템이 추적한다.

Creating a Session
==================

이제 데이터베이스와 대화할 준비가 되었다. 데이터베이스로 향하는 ORM의 "handle"dms :class:`~sqlalchemy.orm.session.Session`\ 이다.
:func:`~sqlalchemy.create_engine`\ 명령문과 같은 수준에서 처음 어플리케이션을 셋업할 때,
우리는 새로운 :class:`~sqlalchemy.orm.session.Session` 객체를 위한 공장으로서 사용될
:class:`~sqlalchemy.orm.session.Session` 클래스를 정의한다.

    >>> from sqlalchemy.orm import sessionmaker
    >>> Session = sessionmaker(bind=engine)

만약 당신의 어플리케이션이 :class:`~sqlalchemy.engine.Engine`\ 를 가지고 있지 않은 경우
모듈 레벨의 객체를 정의할 때 그냥 아래처럼 셋업하면 된다::

    >>> Session = sessionmaker()

나중에, :func:`~sqlalchemy.create_engine`\ 으로 엔진을 만들었을 때
:meth:`~.sessionmaker.configure`\ 를 사용해 :class:`~sqlalchemy.orm.session.Session`\ 에
연결할 수 있다::

    >>> Session.configure(bind=engine)  # once engine is available

.. sidebar:: Session Lifecycle Patterns

    언제 :class:`.Session`\ 을 만들어야 하냐는 질문은 어떤 종류의 어플리케이션을 만들고 있느냐에
    따라 다르다. :class:`.Session`\ 는 로컬에서 특정한 데이터베이스에 연결하는 객체를 위한
    작업 공간일 뿐이라는 점을 명심해라. 만약 어플리케이션 쓰레드를 디너 파티의 게스트라고 생각한다면
    :class:`.Session`\ 은 게스트의 접시이고 클래스가 담고있는 객체는 음식이다 (그리고 데이터베이스는
    ... 부엌?)! 이 주제에 대한 정보는 :ref:`session_faq_whentocreate`\ 에서 더
    찾아볼 수 있다.

이 커스텀 메이드 :class:`~sqlalchemy.orm.session.Session` 클래스는
우리의 데이터베이스에 묶인 새로운 :class:`~sqlalchemy.orm.session.Session` 객체를 생성한다.
다른 트랜즈액선 특성은 :class:`~.sessionmaker`\ 을 호출할 때 정의할 수
있다; 이 부분은 이후의 챕터에서 설명할 것이다. 그 다음, 당신이 데이터베이스와
대화를 하고 싶을 때마다 당신은 :class:`~sqlalchemy.orm.session.Session`\ 를 인스턴스화해야
한다::

    >>> session = Session()

위의 :class:`~sqlalchemy.orm.session.Session`\ 은 SQLite :class:`.Engine`\ 과
결합되어 있지만 아직 어떠한 연결도 열려있지 않다. 최초로 사용될 때 session은 :class:`.Engine`\ 에 의해 유지된 연결
풀에서 연결을 획득하고 우리가 모든 변경사항을 커밋하고 session 객체를 닫기 전까지 연결을 유지한다.


Adding and Updating Objects
===========================

``User`` 객체를 유지하기 위해서, :class:`~sqlalchemy.orm.session.Session`\ 에
:meth:`~.Session.add`\ 로 객체를 추가한다::

    >>> ed_user = User(name='ed', fullname='Ed Jones', password='edspassword')
    >>> session.add(ed_user)

이 시점에서 우리는 인스턴스가 **pending** 상태라고 한다; SQL은 아직 출력되지 않았으며
객채는 아직 데이터베이스의 행으로 나타나지 않았다. :class:`~sqlalchemy.orm.session.Session`\ 는
**flush** 라는 프로세스를 사용해 필요한 경우 즉시 ``Ed Jones``\ 를 유지하기 위해 SQL을
출력할 것이다. 만약 데이터베이스에 ``Ed Jones``\ 를 질문할 하면 모든 계류중인 정보가 처음에
흘러가게 되며 그 다음에 바로 쿼리가 출력될 것이다.

예를 들어, 아래에서 우리는 새로운 :class:`~sqlalchemy.orm.query.Query` 객체를 만들었고
이 객체는 ``User``\ 의 인스턴스를 불러온다. 우리는 ``ed``의 ``name`` 속성으로 필터링을
하고 전체 행 리스트에서 첫 번째 결과만 보여줄 것을 지시했다. 우리가 추가했던 것과 똑같은 ``User``
인스턴스가 반환된다:

.. sourcecode:: python+sql

    {sql}>>> our_user = session.query(User).filter_by(name='ed').first() # doctest:+NORMALIZE_WHITESPACE
    BEGIN (implicit)
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('ed', 'Ed Jones', 'edspassword')
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ?
     LIMIT ? OFFSET ?
    ('ed', 1, 0)
    {stop}>>> our_user
    <User(name='ed', fullname='Ed Jones', password='edspassword')>

사실 :class:`~sqlalchemy.orm.session.Session`\ 는 리턴된 행이 이미 객체의 내부 맵에서
나타난 **똑같은** 행인지 식별한다. 그래서 우리는 실제로 우리가 추가한 것가 동일한 인스턴스를 돌려 받게 된다::

    >>> ed_user is our_user
    True

여기서 작동하는 ORM 컨셉은 :term:`identity map`\ 이라고 하며
:class:`~sqlalchemy.orm.session.Session` 세션에 있는 특정한 행에 대한 모든 작업이
같은 데이터 셋에서 작동함을 보장한다. 일단 특정한 primary key가 :class:`~sqlalchemy.orm.session.Session`\ 에 있으며
:class:`~sqlalchemy.orm.session.Session`\ 의 모든 SQL 쿼리는 항상 특정한 primary key에 대한
동일한 파이썬 객체를 리턴한다; 또한 세션 내에서 동일한 primary key를 이미 보유중인 두 번째 객체를
배치하려고 시도하면 에러가 발생한다.

:func:`~sqlalchemy.orm.session.Session.add_all`\ 를 이용해서 ``User`` 객체를
한 번에 추가할 수 있다:

.. sourcecode:: python+sql

    >>> session.add_all([
    ...     User(name='wendy', fullname='Wendy Williams', password='foobar'),
    ...     User(name='mary', fullname='Mary Contrary', password='xxg527'),
    ...     User(name='fred', fullname='Fred Flinstone', password='blah')])

또한, Ed의 비밀번호가 보호되지 못하고 있다고 판단해, 비밀번호를 변경했다:

.. sourcecode:: python+sql

    >>> ed_user.password = 'f8s7ccs'

:class:`~sqlalchemy.orm.session.Session`\ 는 계속 추적을 하고 있다. 예를 들어,
세션은 ``Ed Jones``\ 가 변경됐다는 것을 안다:

.. sourcecode:: python+sql

    >>> session.dirty
    IdentitySet([<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>])

그리고 새로운 3개의 ``User`` 객체가 계류중이라는 것도 알고 있다:

.. sourcecode:: python+sql

    >>> session.new  # doctest: +SKIP
    IdentitySet([<User(name='wendy', fullname='Wendy Williams', password='foobar')>,
    <User(name='mary', fullname='Mary Contrary', password='xxg527')>,
    <User(name='fred', fullname='Fred Flinstone', password='blah')>])

우리는 :class:`~sqlalchemy.orm.session.Session`\ 에 모든 남아있는 변경점을
데이터베이스에 내보내고 계속 진행중이었던 트랜스액션을 커밋했다.
이 작업은 :meth:`~.Session.commit`\ 을 통해서 수행했다.
:class:`~sqlalchemy.orm.session.Session`\ 은 "ed"의 비밀번호 변경을 위한
``UPDATE`` 명령과, 추가한 3개의 새로운 ``User`` 객체를 위한 ``INSERT`` 명령을
내보냈다:

.. sourcecode:: python+sql

    {sql}>>> session.commit()
    UPDATE users SET password=? WHERE users.id = ?
    ('f8s7ccs', 1)
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('wendy', 'Wendy Williams', 'foobar')
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('mary', 'Mary Contrary', 'xxg527')
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('fred', 'Fred Flinstone', 'blah')
    COMMIT

:meth:`~.Session.commit`\ 은 남아있는 변경점을 데이터베이스로 흘려보내고 트랜스액션을
커밋한다. 세션에 의해 참조된 연결 리소스는 연결 풀로 반환되었다. 이 세션을 통한
후속 작업은 **새로운** 트랜스액션 안에서 발생하며 트랜스액션은 최초로 필요로 할 때
연결 리소스를 다시 획득할 것이다.

이전에 ``None``\ 이었던 Ed의 ``id`` 속성은 이제 값을 가지고 있다:


.. sourcecode:: python+sql

    {sql}>>> ed_user.id # doctest: +NORMALIZE_WHITESPACE
    BEGIN (implicit)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.id = ?
    (1,)
    {stop}1

:class:`~sqlalchemy.orm.session.Session`\ 가 데이터베이스에 새로운 행을 삽입하면,
최초로 접근할 때 또는 즉시, 인스턴스에서 새롭게 생성된 식별자들과 데이터베이스 생성 기본 값을 이용 할 수 있다.
이 경우,
:meth:`~.Session.commit`\ 을 실행한 뒤에 새로운 트랜스액션이 시작되었기 때문에
접근시에 전체 행이 다시 로드된다. SQLAlchemy는 기본적으로 새로운 트랜스액션에
접근했을 때 이전 트랜스액션으로부터 얻은 데이터를 갱신함으로써 가장 최신 데이터를 이용할 수 있게 해준다.
리로드 수준은 :doc:`/orm/session`\ 에서 설명하는대로 조정할 수 있다.

.. topic:: Session Object States

   ``User`` 객체가 :class:`.Session`\ 밖에서, :class:`.Session`\ 안으로 primary key 없이
   이동하면서 실제로 삽입되었고, 4가지 중 3가지의 가능한 "객체 상태"(**transient**, **pending**, **persistent**)
   사이에서 움직였다. 이 상태들과 그 의미를 알고 있는 것은 도움이 되므로 :ref:`session_object_states`\ 에서
   간단한 개요를 읽어 보기 바란다.

Rolling Back
============
:class:`~sqlalchemy.orm.session.Session`\ 은 트랜스액션 내에서 작동하기 때문에
변경한 것을 롤백할 수도 있다. 되돌릴 변경사항 두 개를 만들어보자;
``ed_user``\ 의 사용자 이름을 ``Edwardo``\ 로 설정한다:

.. sourcecode:: python+sql

    >>> ed_user.name = 'Edwardo'

그리고 잘못 입력된 사용자, ``fake_user``\ 를 추가한다:

.. sourcecode:: python+sql

    >>> fake_user = User(name='fakeuser', fullname='Invalid', password='12345')
    >>> session.add(fake_user)

세션으로 쿼리를 하면, 변경 사항이 현재의 트랜스액션으로 들어간 것을 확인할 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).filter(User.name.in_(['Edwardo', 'fakeuser'])).all()
    UPDATE users SET name=? WHERE users.id = ?
    ('Edwardo', 1)
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('fakeuser', 'Invalid', '12345')
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name IN (?, ?)
    ('Edwardo', 'fakeuser')
    {stop}[<User(name='Edwardo', fullname='Ed Jones', password='f8s7ccs')>, <User(name='fakeuser', fullname='Invalid', password='12345')>]

롤백하면, ``ed_user``\ 의 이름이 ``ed``\ 로 돌아가고 ``fake_user``\ 가 세션에서
사라지는 것을 확인할 수 있다.

.. sourcecode:: python+sql

    {sql}>>> session.rollback()
    ROLLBACK
    {stop}

    {sql}>>> ed_user.name
    BEGIN (implicit)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.id = ?
    (1,)
    {stop}u'ed'
    >>> fake_user in session
    False

SELECT를 이용하면 데이터베이스에서 생성된 변경사항을 볼 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).filter(User.name.in_(['ed', 'fakeuser'])).all()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name IN (?, ?)
    ('ed', 'fakeuser')
    {stop}[<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>]

.. _ormtutorial_querying:

Querying
========

:class:`~sqlalchemy.orm.query.Query` 객체는
:class:`~sqlalchemy.orm.session.Session`\ 의
:class:`~sqlalchemy.orm.session.Session.query()` 메서드를 사용해 생성할 수 있다.
이 함수는 여러 인자를 받으며 인자는 클래스와 클래스 계측 설명자의 조합이 될 수 있다.
아래는 ``User`` 인스턴스를 불러오는 :class:`~sqlalchemy.orm.query.Query`\ 다.
반복 컨텍스트에서 구해질 때, 존재하는 ``User`` 객체 리스트가 리턴된다:

.. sourcecode:: python+sql

    {sql}>>> for instance in session.query(User).order_by(User.id):
    ...     print(instance.name, instance.fullname)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users ORDER BY users.id
    ()
    {stop}ed Ed Jones
    wendy Wendy Williams
    mary Mary Contrary
    fred Fred Flinstone

:class:`~sqlalchemy.orm.query.Query`\ 는 인자로 ORM 계측 설명자도 받을 수 있다.
다중 클래스 엔티티나 컬럼 기반 엔티티가 :class:`~sqlalchemy.orm.session.Session.query()`\ 에
인자로 전달 되면 리턴되는 결과는 튜플로 나타난다:

.. sourcecode:: python+sql

    {sql}>>> for name, fullname in session.query(User.name, User.fullname):
    ...     print(name, fullname)
    SELECT users.name AS users_name,
            users.fullname AS users_fullname
    FROM users
    ()
    {stop}ed Ed Jones
    wendy Wendy Williams
    mary Mary Contrary
    fred Fred Flinstone

:class:`~sqlalchemy.orm.query.Query`\ 로 리턴되는 튜플은 *명명된* 튜플이며, :class:`.KeyedTuple`\ 에
의해 제공되고 일반 파이썬 객체처럼 다루어진다. 속성의 속성 이름과, 클래스의 클래스 이름은 동일하다:

.. sourcecode:: python+sql

    {sql}>>> for row in session.query(User, User.name).all():
    ...    print(row.User, row.name)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    ()
    {stop}<User(name='ed', fullname='Ed Jones', password='f8s7ccs')> ed
    <User(name='wendy', fullname='Wendy Williams', password='foobar')> wendy
    <User(name='mary', fullname='Mary Contrary', password='xxg527')> mary
    <User(name='fred', fullname='Fred Flinstone', password='blah')> fred

개별 컬럼 표현의 이름은 :meth:`~.ColumnElement.label` 구조를 사용해 조정할 수 있으
이 구조는 :class:`.ColumnElement` 파생 객체와 하나의 클래스에 맵핑된 클래스 속성(예, ``User.name``)에서
사용할 수 있다:

.. sourcecode:: python+sql

    {sql}>>> for row in session.query(User.name.label('name_label')).all():
    ...    print(row.name_label)
    SELECT users.name AS name_label
    FROM users
    (){stop}
    ed
    wendy
    mary
    fred

:meth:`~.Session.query` 호출에 여러 엔티티가 있다는 것을 가정하면 ``User`` 같은 전체 엔티티에 주어진 이름은
:func:`~.sqlalchemy.orm.aliased`\ 를 사용해 제어할 수 있다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.orm import aliased
    >>> user_alias = aliased(User, name='user_alias')

    {sql}>>> for row in session.query(user_alias, user_alias.name).all():
    ...    print(row.user_alias)
    SELECT user_alias.id AS user_alias_id,
            user_alias.name AS user_alias_name,
            user_alias.fullname AS user_alias_fullname,
            user_alias.password AS user_alias_password
    FROM users AS user_alias
    (){stop}
    <User(name='ed', fullname='Ed Jones', password='f8s7ccs')>
    <User(name='wendy', fullname='Wendy Williams', password='foobar')>
    <User(name='mary', fullname='Mary Contrary', password='xxg527')>
    <User(name='fred', fullname='Fred Flinstone', password='blah')>

기본적인 :class:`~sqlalchemy.orm.query.Query` 동작은 LIMIT과 OFFSET 출력 포함하며,
가장 편리하게 파이썬 어레이 슬라이스 이용하고 일반적으로 ORDER BY와 함께 사용된다:

.. sourcecode:: python+sql

    {sql}>>> for u in session.query(User).order_by(User.id)[1:3]:
    ...    print(u)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users ORDER BY users.id
    LIMIT ? OFFSET ?
    (2, 1){stop}
    <User(name='wendy', fullname='Wendy Williams', password='foobar')>
    <User(name='mary', fullname='Mary Contrary', password='xxg527')>

결과 필터링은 키워드 인자를 사용하는 :func:`~sqlalchemy.orm.query.Query.filter_by`\ 를
사용할 수도 있고:

.. sourcecode:: python+sql

    {sql}>>> for name, in session.query(User.name).\
    ...             filter_by(fullname='Ed Jones'):
    ...    print(name)
    SELECT users.name AS users_name FROM users
    WHERE users.fullname = ?
    ('Ed Jones',)
    {stop}ed

플렉서블한 SQL 표현 언어 구조를 사용하는 :func:`~sqlalchemy.orm.query.Query.filter`\ 를
사용할 수도 있다. 이 경우 매핑된 클래스의 클래스 수준 속성과 함께 일반 파이썬 연산자를
사용할 수 있게 해준:

.. sourcecode:: python+sql

    {sql}>>> for name, in session.query(User.name).\
    ...             filter(User.fullname=='Ed Jones'):
    ...    print(name)
    SELECT users.name AS users_name FROM users
    WHERE users.fullname = ?
    ('Ed Jones',)
    {stop}ed

:class:`~sqlalchemy.orm.query.Query` 객체는 완전히 **generative** 하며, 이는
대부분의 메서드 호출은 새로운 :class:`~sqlalchemy.orm.query.Query` 객체를 리턴하며 조건을
더 추가시킬 수 있다. 예를 들어 전체 이름이 "Ed Jones"고 이름이 "ed"인 사용자를 쿼리하고 싶으면,
:func:`~sqlalchemy.orm.query.Query.filter`\ 를 두 번 호출하면 되며, 조건은 ``AND`` 사용해서
결합된다:

.. sourcecode:: python+sql

    {sql}>>> for user in session.query(User).\
    ...          filter(User.name=='ed').\
    ...          filter(User.fullname=='Ed Jones'):
    ...    print(user)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ? AND users.fullname = ?
    ('ed', 'Ed Jones')
    {stop}<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>

Common Filter Operators
-----------------------

아래는 :func:`~sqlalchemy.orm.query.Query.filter` 에서 가장
일반적으로 쓰이는 연산자 목록이다:

* :meth:`equals <.ColumnOperators.__eq__>`::

    query.filter(User.name == 'ed')

* :meth:`not equals <.ColumnOperators.__ne__>`::

    query.filter(User.name != 'ed')

* :meth:`LIKE <.ColumnOperators.like>`::

    query.filter(User.name.like('%ed%'))

 .. note:: :meth:`.ColumnOperators.like`\ 는 LIKE 연산자를 렌더링하며,
    몇몇 백엔드 에서는 대소문자를 구별하지 않고, 몇몇 백엔드에서는
    대소문자를 구별한다. 대소문자를 구별하지 않는 비교를 보장하려면
    :meth:`.ColumnOperators.ilike`\ 를 사용하라.

* :meth:`ILIKE <.ColumnOperators.ilike>` (case-insensitive LIKE)::

    query.filter(User.name.ilike('%ed%'))

 .. note:: 대부분의 백엔드는 ILIKE를 직접적으로 지원하지 않는다. 그런 경우
    :meth:`.ColumnOperators.ilike` 연산자는 LIKE를 각 피연산자에 적용된 LOWER SQL 함수와
    결합한 표현을 렌더링한다.

* :meth:`IN <.ColumnOperators.in_>`::

    query.filter(User.name.in_(['ed', 'wendy', 'jack']))

    # works with query objects too:
    query.filter(User.name.in_(
        session.query(User.name).filter(User.name.like('%ed%'))
    ))

* :meth:`NOT IN <.ColumnOperators.notin_>`::

    query.filter(~User.name.in_(['ed', 'wendy', 'jack']))

* :meth:`IS NULL <.ColumnOperators.is_>`::

    query.filter(User.name == None)

    # alternatively, if pep8/linters are a concern
    query.filter(User.name.is_(None))

* :meth:`IS NOT NULL <.ColumnOperators.isnot>`::

    query.filter(User.name != None)

    # alternatively, if pep8/linters are a concern
    query.filter(User.name.isnot(None))

* :func:`AND <.sql.expression.and_>`::

    # use and_()
    from sqlalchemy import and_
    query.filter(and_(User.name == 'ed', User.fullname == 'Ed Jones'))

    # or send multiple expressions to .filter()
    query.filter(User.name == 'ed', User.fullname == 'Ed Jones')

    # or chain multiple filter()/filter_by() calls
    query.filter(User.name == 'ed').filter(User.fullname == 'Ed Jones')

 .. note::  파이썬 ``and`` 연산자가 **아니라** :func:`.and_`\ 를 사용하고 있는지
    확인하라.

* :func:`OR <.sql.expression.or_>`::

    from sqlalchemy import or_
    query.filter(or_(User.name == 'ed', User.name == 'wendy'))

 .. note::  파이썬 ``or`` 연산자가 아니라 :func:`.or_`\ 를 사용하고 있는지
    확인하라.

* :meth:`MATCH <.ColumnOperators.match>`::

    query.filter(User.name.match('wendy'))

 .. note::

    :meth:`~.ColumnOperators.match`\ 는 데이터베이스 지정 ``MATCH``\ 나 ``CONTAINS`` 함수를
    사용한다; 이 동작은 백엔드에 따라 다르며, SQLite 같은 몇몇 백엔드에서는 사용할 수 없다.

Returning Lists and Scalars
---------------------------

:class:`.Query`\ 의 많은 메서드는 즉시 SQL을 출력하고 로드된 데이터베이스 결과를 포함하는 값을
리턴한다. 아래는 간단한 예시이다:

* :meth:`~.Query.all()`\ 는 리스트를 리턴한다:

  .. sourcecode:: python+sql

      >>> query = session.query(User).filter(User.name.like('%ed')).order_by(User.id)
      {sql}>>> query.all()
      SELECT users.id AS users_id,
              users.name AS users_name,
              users.fullname AS users_fullname,
              users.password AS users_password
      FROM users
      WHERE users.name LIKE ? ORDER BY users.id
      ('%ed',)
      {stop}[<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>,
            <User(name='fred', fullname='Fred Flinstone', password='blah')>]

* :meth:`~.Query.first()`\는 한계를 하나로 조정하고 첫 번째 결과를 스칼라로 리턴합니다:

  .. sourcecode:: python+sql

      {sql}>>> query.first()
      SELECT users.id AS users_id,
              users.name AS users_name,
              users.fullname AS users_fullname,
              users.password AS users_password
      FROM users
      WHERE users.name LIKE ? ORDER BY users.id
       LIMIT ? OFFSET ?
      ('%ed', 1, 0)
      {stop}<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>

* :meth:`~.Query.one()`\ 는 모든 행을 완전히 불러오고, 정확히 한 객체 아이덴티티나 컴포짓 행이 결과에
  존재하지 않으면 에러를 발생시킨다. 여러 행이 찾아진 경우:

  .. sourcecode:: python+sql

      >>> user = query.one()
      Traceback (most recent call last):
      ...
      MultipleResultsFound: Multiple rows were found for one()

  찾아진 행이 없는 경우:

  .. sourcecode:: python+sql

      >>> user = query.filter(User.id == 99).one()
      Traceback (most recent call last):
      ...
      NoResultFound: No row was found for one()

  :meth:`~.Query.one` 메서드는 "no items found"와 "multiple items found"를 다르게
  처리하기를 기대하는 시스템에 유용하다; 예를 들어, 찾은 결과가 없을 때 "404 not found"를
  발생키길 원하고 여러 결과가 찾아졌을 경우 어플리케이션 에러를 발생시키기 원하는 RESTful 웹서비스.

* :meth:`~.Query.one_or_none`\ 는 :meth:`~.Query.one`\ 와 비슷하지만, 결과를 찾지 못했을 때,
  에러를 발생시키지 않는 다는 점이 다르다; 그냥 ``None`` 값을 리턴한다. 그러나, :meth:`~.Query.one` 처럼
  여러 결과를 찾았을 경우 에러를 발생시킨다.

* :meth:`~.Query.scalar`\ 는 :meth:`~.Query.one` 메서드를 불러오며, 성공시에
  행의 첫 번째 컬럼을 리턴한다:

  .. sourcecode:: python+sql

      >>> query = session.query(User.id).filter(User.name == 'ed').\
      ...    order_by(User.id)
      {sql}>>> query.scalar()
      SELECT users.id AS users_id
      FROM users
      WHERE users.name = ? ORDER BY users.id
      ('ed',)
      {stop}1

.. _orm_tutorial_literal_sql:

Using Textual SQL
-----------------

리터럴 스트링은 :func:`~.expression.text` 구조로 사용을 명시함으로써
:class:`~sqlalchemy.orm.query.Query`\ 에서 플렉서블하게
사용할 수 있고 대부분의 메서드에 적용 가능하다. 예를 들어,
:meth:`~sqlalchemy.orm.query.Query.filter()`\ 와
:meth:`~sqlalchemy.orm.query.Query.order_by()`\ 가 있다:

.. sourcecode:: python+sql

    >>> from sqlalchemy import text
    {sql}>>> for user in session.query(User).\
    ...             filter(text("id<224")).\
    ...             order_by(text("id")).all():
    ...     print(user.name)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE id<224 ORDER BY id
    ()
    {stop}ed
    wendy
    mary
    fred

바인드 파라미터는 콜론을 사용해서 스트링 기반 SQL로 지정될 수 있다.
:meth:`~sqlalchemy.orm.query.Query.params()` 메서드를 사용해 값을 지정하라:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).filter(text("id<:value and name=:name")).\
    ...     params(value=224, name='fred').order_by(User.id).one()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE id<? and name=? ORDER BY users.id
    (224, 'fred')
    {stop}<User(name='fred', fullname='Fred Flinstone', password='blah')>

전체 명령을 나타내는 :func:`.text` 구조를
:meth:`~sqlalchemy.orm.query.Query.from_statement()` 에 전달해서 완전한 스트링 기반 명령을 사용할 수 있다.
추가적인 지정자 없이, 스트링 SQL에 있는 컬럼은 이름에 기반한 모델 컬럼과 매치된다.
아래는 모든 컬럼을 로드하기 위해 별표를 사용했다:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).from_statement(
    ...                     text("SELECT * FROM users where name=:name")).\
    ...                     params(name='ed').all()
    SELECT * FROM users where name=?
    ('ed',)
    {stop}[<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>]

간단한 경우에는 name 에서 일치하는 컬럼이 작동하지만 중복된 컬럼 이름을 포함하는 복잡한 명령을 처리하거나
특정 이름과 쉽게 일치하지 않는 익명화된 ORM 구조를 사용할 때는 다루기 어려워질 수 있다.
추가적으로, 결과 행들을 처리할 때 필요하다고 판단되는 매핑된 컬럼에 존재하는 타이핑 동작이
존재한다. 이 경우, :func:`~.expression.text` 구조가 텍스트 형식 SQL을 위치에 따라 Core나 ORM 매핑된
컬럼 표현식에 연결해준다; 컬럼 표현식을 위치 인자로 :meth:`.TextClause.columns`\ 에 전달함으로써
작업을 수행할 수 있다:

.. sourcecode:: python+sql

    >>> stmt = text("SELECT name, id, fullname, password "
    ...             "FROM users where name=:name")
    >>> stmt = stmt.columns(User.name, User.id, User.fullname, User.password)
    {sql}>>> session.query(User).from_statement(stmt).params(name='ed').all()
    SELECT name, id, fullname, password FROM users where name=?
    ('ed',)
    {stop}[<User(name='ed', fullname='Ed Jones', password='f8s7ccs')>]

.. versionadded:: 1.1

    :meth:`.TextClause.columns` 메서드는 현재 일반 텍스트 SQL 결과 집합에 위치상으로
    일치하게 될 컬럼 표현식을 받아들여서 SQL 명령에서 컬럼 이름이 매치되거나 유니크해야 할
    필요가 없어졌다.

:func:`~.expression.text` 구조에서 selecting을 할 때, :class:`.Query`\ 는 여전히 리턴될
엔티티와 컬럼을 지정할 수 있다; 다른 경우처럼 ``query(User)`` 대신에 개별적으로 컬럼을 요청할 수도 있다:

.. sourcecode:: python+sql

    >>> stmt = text("SELECT name, id FROM users where name=:name")
    >>> stmt = stmt.columns(User.name, User.id)
    {sql}>>> session.query(User.id, User.name).\
    ...          from_statement(stmt).params(name='ed').all()
    SELECT name, id FROM users where name=?
    ('ed',)
    {stop}[(1, u'ed')]

.. seealso::

    :ref:`sqlexpression_text` - Core 전용 쿼리 관점에서 설명된
    :func:`.text` 구조.

Counting
--------

:class:`~sqlalchemy.orm.query.Query`\ 는 카운팅을 위한 편리한 메서드인
:meth:`~sqlalchemy.orm.query.Query.count()`\ 을 포함하고 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).filter(User.name.like('%ed')).count()
    SELECT count(*) AS count_1
    FROM (SELECT users.id AS users_id,
                    users.name AS users_name,
                    users.fullname AS users_fullname,
                    users.password AS users_password
    FROM users
    WHERE users.name LIKE ?) AS anon_1
    ('%ed',)
    {stop}2

.. sidebar:: Counting on ``count()``

    :meth:`.Query.count`\ 는 서브 쿼리가 기존 쿼리에 필요한지를 추측하려고 할 때는
    매우 복잡한 메서드가 됐었고 몇몇 특이한 경우에는 올바르게 작동하지 않았다.
    이제 간단한 서브 쿼리를 사용하기 때문에 길이도 두 줄밖에 되지 않고 항상 올바른 답을
    리턴한다. 특정한 명령이 서브 쿼리가 존재하는 것을 절대 용납하지 않는 경우
    ``func.count()``\ 를 사용하라.

:meth:`~.Query.count()` 메서드는 SQL 명령이 얼마만큼의 행을 리턴해야 하는지를 결정하기
위해 사용된다. 위에 있는 생성된 SQL을 보면 SQLAlchemy는 항상 쿼리 하려는 것을 서브쿼리에 넣고,
그것으로부터 행을 센다. 몇몇 경우에는 더 간단한 ``SELECT count(*) FROM table``\ 로 축소될 수도
있다. 그러나, 최신 버전의 SQLAlchemy는 더 명시적인 수단을 사용해서 정확한 SQL을 내보낼 수 있기 때문에
이것이 언제 적헐한지를 추측하지 않는다

특별히 "things to be counted"를 표시해야 하는 상황의 경우, "count" 함수를
:attr:`~sqlalchemy.sql.expression.func` 구조에서 이용 가능한 ``func.count()`` 표현을
사용해서 직접 지정할 수 있다. 아래에서는0 각각의 user name의 카운트를 리턴하기 위해서 사용했다:

.. sourcecode:: python+sql

    >>> from sqlalchemy import func
    {sql}>>> session.query(func.count(User.name), User.name).group_by(User.name).all()
    SELECT count(users.name) AS count_1, users.name AS users_name
    FROM users GROUP BY users.name
    ()
    {stop}[(1, u'ed'), (1, u'fred'), (1, u'mary'), (1, u'wendy')]

단순한 ``SELECT count(*) FROM table``\ 을 위해서, 아래처럼 적용할 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(func.count('*')).select_from(User).scalar()
    SELECT count(?) AS count_1
    FROM users
    ('*',)
    {stop}4

만약 카운트를 직접 ``User`` primart key로 표현하면, :meth:`~.Query.select_from` 사용이
제될 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(func.count(User.id)).scalar()
    SELECT count(users.id) AS count_1
    FROM users
    ()
    {stop}4

.. _orm_tutorial_relationship:

Building a Relationship
=======================

``User``\ 와 관련된 두 번째 테이블을 어떻게 매핑하고 쿼리할지 생각해보자.
우리 시스템의 User는 그들의 username과 결합된 이메일 주소를 저장할 수 있다.
이것은 ``User``\ 에서 이메일 주소를 저장하는 새로운 테이블(``addresses``\ 로 부를 것이다)
로 향하는 기본적인 일대다 결합을 의미한다. declarative를 이용해, 매핑된 클래스 ``Address``\ 와 함께
이 테이블을 정의할 것이다:

.. sourcecode:: python

    >>> from sqlalchemy import ForeignKey
    >>> from sqlalchemy.orm import relationship

    >>> class Address(Base):
    ...     __tablename__ = 'addresses'
    ...     id = Column(Integer, primary_key=True)
    ...     email_address = Column(String, nullable=False)
    ...     user_id = Column(Integer, ForeignKey('users.id'))
    ...
    ...     user = relationship("User", back_populates="addresses")
    ...
    ...     def __repr__(self):
    ...         return "<Address(email_address='%s')>" % self.email_address

    >>> User.addresses = relationship(
    ...     "Address", order_by=Address.id, back_populates="user")

위의 클래스는 :class:`.ForeignKey` 구조를 소개하고 있다. 이 구조는 :class:`.Column`\ 에
적용하는 명령어로 이 컬럼에 있는 값은 반드시 지명된 외부의 컬럽에 존재하는 값과 :term:`constrained` 되어야
한다는 것을 나타낸다. 이것은 관계형 데이터베이스의 핵심 기능 중 하나로, 연결되지 않은 테이블 집합을
오버래핑된 풍부한 관계를 가질 수 있게 변환시켜주는 접착제다. 위의 :class:`.ForeignKey`\ 는 ``addresses.user_id`` 컬럼에 있는
값은 반드시 ``users.id`` 컬럼에 있는 값과 묶여있어야 한다는 것을 나타낸다. 즉, 일종의 primary key다.


두 번째 명령어 :func:`.relationship`\ 는 ORM에게 ``Address``\ 자체가 ``User`` 클래스와
``Address.user`` 속성을 사용해 연결되어야 한다는 것을 말해준다.
:func:`.relationship`\ 는 두 테이블 사이의 foreign key 관계를 사용해서 ``Address.user``\ 가
:term:`many to one`\ 이 되도록 하는 연결의 성질을 결정한다.
추가적인 :func:`.relationship` 명령어는 매핑된 ``User`` 클래스의 ``User.addresses`` \ 속성에
위치한다. 두 :func:`.relationship` 명령 내에서 :paramref:`.relationship.back_populates` 변수는 상호간에
속성 이름을 참조하기 위해서 할당된다; 그렇게 함으로써 각각의 :func:`.relationship`\ 은 역으로 표현된 것과 같이 동일한
관계에 대한 지능적인 결정을 할 수 있게 된다; 한 쪽에서 ``Address.user``\ 가 ``User`` 인스턴스를 참조하고, 다른 쪽에서
``User.addresses`` 가 ``Address`` 인스턴스의 리스트를 참조한다.

.. note::

    :paramref:`.relationship.back_populates`\ 는 가장 흔한 SQlAlchemy 특징인
    :paramref:`.relationship.backref`\ 의 새로운 버전이다. :paramref:`.relationship.backref`
    변수는 사라지지 않았으며 앞으로도 사용가능할 것이다.
    :paramref:`.relationship.back_populates`\ 는 좀 더 상세하고 쉽게 조정할 수 있는 점을
    제외하고는 동일한다. 전체 내용에 대한 개요는 :ref:`relationships_backref` 섹션에서
    볼 수 있다.

다대일 relationship의 반대는 :term:`one to many`\ 다.
사용가능한 전체 :func:`.relationship` 설정은 :ref:`relationship_patterns`\ 를
참고하라.

두 보완적인 relationship ``Address.user``\ 와 ``User.addresses``\ 는
:term:`bidirectional relationship`\ 로서 참조되며, 이는 SQLAlchemy ORM의 중요한
핵심적인 기능이다. :ref:`relationships_backref`\ 에서 "backref" 기능에 대해 자세하게
다루고 있다.

다른 클래스와 연관된 :func:`.relationship`\ 의 인수는 Decalarative system이
사용중이면 문자열을 사용해서 지정할 수 있다. 모든 매핑이 완로되면, 이 문자열들은
실제 인자를 생성하기 위한 파이썬 표현식으로 인식되며 위의 경우에서는 ``User`` 클래스가 된다.
평가 중에 허용되는 이름은 선언된 base로 생성된 모든 클래스의 이름을 포함한다.

인자 스타일에 대한 더 자세한 정보는 :func:`.relationship`\ 에 관한 독스트링을 참고하라.

.. topic:: Did you know ?

    * 대부분의 관계형 데이터베이스의 FOREIGN KEY 제약은 primary key 컬럼이나, UNIQUE 제약이
      걸려있는 컬럼과만 연결이 가능하다.
    * 여러 primary key 컬럼을 참조하거나 여러 컬럼을 가지고 있는 FOREIGN KEY 제약은
      "composite foreign key"로 알려져 있다. 이 키는 위의 컬럼들의 하위 집합도
      참조할 수 있다.
    * FOREIGN KEY 컬럼은 참초하는 컬럼이나 행의 변와에 따라 자동적으로 자기자신을 업데이트 한다.
      이것은 CASCADE *referential action*\ 으로 알려져있고, 관계형 데이터베이스의 내장 함수다.
    * FOREIGN KEY\ 는 자신이 속한 테이블을 참조할 수 있다. 이것은 "sefl_referential" foreign key로
      알려져 있다. .
    * `Foreign Key - Wikipedia <http://en.wikipedia.org/wiki/Foreign_key>`_\ 에서 foreign key에
      대한 더 자세한 내용을 확인할 수 있다.

우리는 데이터베이스에 ``addresses`` 테이블을 만들어야할 필요가 있다. 그래서 우리의 metadata로부터
또다른 CREATE 명령을 내보낼 것이고, 이 때 이미 생성된 테이블은 알아서 스킵될 것이다.

.. sourcecode:: python+sql

    {sql}>>> Base.metadata.create_all(engine)
    PRAGMA...
    CREATE TABLE addresses (
        id INTEGER NOT NULL,
        email_address VARCHAR NOT NULL,
        user_id INTEGER,
        PRIMARY KEY (id),
         FOREIGN KEY(user_id) REFERENCES users (id)
    )
    ()
    COMMIT

Working with Related Objects
============================

이제 ``User``\ 를 만들 때, 빈 ``addresses`` 컬렉션이 나타난다.
집합형이나 사전형 같은 다양한 컬렉션 유형이 가능하지만 (자세한 내용은 :ref:`custom_collections`\ 를
참고하라), 기본적으로 컬렉션은 파이썬 리스트다.

.. sourcecode:: python+sql

    >>> jack = User(name='jack', fullname='Jack Bean', password='gjffdd')
    >>> jack.addresses
    []

우리는 자유롭게 ``Address`` 객체를 ``User`` 객체에 추가할 수 있다.
이 경우 리스트 전체를 직접 할당할 것이다:

.. sourcecode:: python+sql

    >>> jack.addresses = [
    ...                 Address(email_address='jack@google.com'),
    ...                 Address(email_address='j25@yahoo.com')]

bidirectional relationship을 사용할 때, 한 방향에서 추가된 요소는 자동적으로
다른 방향에서 보이게 된다. 이 동작은 변경시 속성에 기반해 발생하며 평가는 SQL을 사용하지 않고
파이썬으로 이루어진다:

.. sourcecode:: python+sql

    >>> jack.addresses[1]
    <Address(email_address='j25@yahoo.com')>

    >>> jack.addresses[1].user
    <User(name='jack', fullname='Jack Bean', password='gjffdd')>

``Jack Bean``\ 를 데이터베이스에 추가하고 커밋하자. **cascading**\ 이라는
프로세스를 사용해서 ``addresses``\ 에 해당하는 두 ``Address`` 멤버 뿐만 아니라
``jack``\ 둘 다 세션에 한 번에 추가된다:

.. sourcecode:: python+sql

    >>> session.add(jack)
    {sql}>>> session.commit()
    INSERT INTO users (name, fullname, password) VALUES (?, ?, ?)
    ('jack', 'Jack Bean', 'gjffdd')
    INSERT INTO addresses (email_address, user_id) VALUES (?, ?)
    ('jack@google.com', 5)
    INSERT INTO addresses (email_address, user_id) VALUES (?, ?)
    ('j25@yahoo.com', 5)
    COMMIT

Jack에 대해 쿼리하면 Jack을 돌려받는다. 아직 Jack의 addresses에 대한 SQL은 발행되지 않았다:

.. sourcecode:: python+sql

    {sql}>>> jack = session.query(User).\
    ... filter_by(name='jack').one()
    BEGIN (implicit)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ?
    ('jack',)

    {stop}>>> jack
    <User(name='jack', fullname='Jack Bean', password='gjffdd')>

``addresses`` 컬렉션을 보자. SQL을 보아라:

.. sourcecode:: python+sql

    {sql}>>> jack.addresses
    SELECT addresses.id AS addresses_id,
            addresses.email_address AS
            addresses_email_address,
            addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE ? = addresses.user_id ORDER BY addresses.id
    (5,)
    {stop}[<Address(email_address='jack@google.com')>, <Address(email_address='j25@yahoo.com')>]

``addresses`` 컬렉션에 액세스 할 때, SQL이 갑자기 발행된다. 이것은 :term:`lazy loading` relationship의
한 예이다. ``addresses`` 컬렉션이 이제 로드됐고 일반적인 리스트처럼 동작한다. 잠시 뒤에
이 컬렉션 로딩을 최척화 하는 법을 다룰 것이다.

.. _ormtutorial_joins:

Querying with Joins
===================

이제 두 테이블이 있기 때문에 :class:`.Query`\ 의 더 많은 기능들을 볼 수 있다.
특히 동시에 두 테이블을 다루는 커리를 만드는 방법을 보게 될 것이다.
`Wikipedia page on SQL JOIN
<http://en.wikipedia.org/wiki/Join_%28SQL%29>`_\ 은 여기서 소게 할 몇몇 join 테크닉에 대한
좋은 소개를 제공해준다.

``Join``\ 과 ``Address``\ 사이에 간단한 암시적 join을 생성하기 위해서
우리는 관계된 컬럼을 동일시하는 :meth:`.Query.filter()`\ 를 사용할 것이다.
아래에서 우리는 ``User``\ 와 ``Address``\ 개체를
이 메서드를 사용해 한 번에 로드했다:

.. sourcecode:: python+sql

    {sql}>>> for u, a in session.query(User, Address).\
    ...                     filter(User.id==Address.user_id).\
    ...                     filter(Address.email_address=='jack@google.com').\
    ...                     all():
    ...     print(u)
    ...     print(a)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password,
            addresses.id AS addresses_id,
            addresses.email_address AS addresses_email_address,
            addresses.user_id AS addresses_user_id
    FROM users, addresses
    WHERE users.id = addresses.user_id
            AND addresses.email_address = ?
    ('jack@google.com',)
    {stop}<User(name='jack', fullname='Jack Bean', password='gjffdd')>
    <Address(email_address='jack@google.com')>

반면에, 실제 SQL JOIN 신택스는, :meth:`.Query.join` 메서드를 사용해 쉽게 만들 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(User).join(Address).\
    ...         filter(Address.email_address=='jack@google.com').\
    ...         all()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users JOIN addresses ON users.id = addresses.user_id
    WHERE addresses.email_address = ?
    ('jack@google.com',)
    {stop}[<User(name='jack', fullname='Jack Bean', password='gjffdd')>]

:meth:`.Query.join`\ 는 ``User``\ 과 ``Address``\ 를 join하는 방법을 알고 있다.
왜냐하면 둘 사이에는 단 하나의 foreign key가 존재하기 때문이다. foreign key가 없거나,
여러개 있다면 아래의 형식을 사용했을 때, :meth:`.Query.join`\ 가 더 잘 작동한다::

    query.join(Address, User.id==Address.user_id)    # explicit condition
    query.join(User.addresses)                       # specify relationship from left to right
    query.join(Address, User.addresses)              # same, with explicit target
    query.join('addresses')                          # same, using a string

예상했다시피 같은 아이디어가 :meth:`~.Query.outerjoin`\ 함수를 통해 "outer" join에서도 사용된다::

    query.outerjoin(User.addresses)   # LEFT OUTER JOIN

:meth:`~.Query.join`\ 에 대한 참고 문서는 상세한 정보와 이 메서드에 의해 용인되는 호출 스타일에 대한
예시를 담고 있다; :meth:`~.Query.join'\ 은 SQL-fluent 어플리케이션 사용의 중심에 있는 중요한
메서드다.

.. topic:: What does :class:`.Query` select from if there's multiple entities?

    :meth:`.Query.join` 메서드는 ON clause가 생략됐을 때나, ON cluase가 일반 SQL 표현식일 때,
    개체 리스트에 있는 **일반적으로 가장 촤측의 항목에서 join한다** JOIN의 리스트에 있는 첫 번째
    개체를 조작하고 싶으면 :meth:`.Query.select_from` 메서드를 사용하라::

        query = session.query(User, Address).select_from(Address).join(User)


.. _ormtutorial_aliases:

Using Aliases
-------------

여러 테이블에 걸친 쿼리를 할 때, 같은 테이블이 한 번 이상 참조되어야 한다면, SQL은 일반적으로
해당 테이블이 다른 이름으로 *aliased*\ 할 것을 요구하며 이를 통해서 그 테이블이 다른 곳에서
등장하는 것을 구분할 수 있다. :class:`~sqlalchemy.orm.query.Query`\ 는 이것을
:attr:`~sqlalchemy.orm.aliased` 구조를 사용해서 아주 명시적으로 지원한다.
아래에서 우리는 ``Address`` 개체를 두 번 join 시켜서, 두 개의 다른 이메일 주소를 가진 사용자를
동시에 찾아냈다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.orm import aliased
    >>> adalias1 = aliased(Address)
    >>> adalias2 = aliased(Address)
    {sql}>>> for username, email1, email2 in \
    ...     session.query(User.name, adalias1.email_address, adalias2.email_address).\
    ...     join(adalias1, User.addresses).\
    ...     join(adalias2, User.addresses).\
    ...     filter(adalias1.email_address=='jack@google.com').\
    ...     filter(adalias2.email_address=='j25@yahoo.com'):
    ...     print(username, email1, email2)
    SELECT users.name AS users_name,
            addresses_1.email_address AS addresses_1_email_address,
            addresses_2.email_address AS addresses_2_email_address
    FROM users JOIN addresses AS addresses_1
            ON users.id = addresses_1.user_id
    JOIN addresses AS addresses_2
            ON users.id = addresses_2.user_id
    WHERE addresses_1.email_address = ?
            AND addresses_2.email_address = ?
    ('jack@google.com', 'j25@yahoo.com')
    {stop}jack jack@google.com j25@yahoo.com

Using Subqueries
----------------

:class:`~sqlalchemy.orm.query.Query`\ 는 하위쿼리로 사용될 수 있는 명령을 생성하는 데도 적합하다.
``User`` 객체를 각 user가 몇 개의 ``Address`` 기록을 가지고 있는지 카운트 한 결과와 같이
로드하고 싶다고 가정하자. SQL을 생성하기 가장 좋은 방법은 카운팅된 addresses를 user id로 group by해서 얻고
부모에 JOIN 시키는 것이다. 이 경우 우리는 LEFT OUTER JOIN을 사용했고 addresses가 없는
user 행을 돌려 받았다::

    SELECT users.*, adr_count.address_count FROM users LEFT OUTER JOIN
        (SELECT user_id, count(*) AS address_count
            FROM addresses GROUP BY user_id) AS adr_count
        ON users.id=adr_count.user_id

:class:`~sqlalchemy.orm.query.Query`\ 를 사용해서, 이러한 명령을 내부에서 밖으로 생성할 수 있다.
``statement`` 접근자는 특정한 :class:`~sqlalchemy.orm.query.Query`\ 에 의해 생성된 명령을 나타내는
SQL 표현식을 리턴한다. - 이것은 :func:`~.expression.select` 구조의 인스턴스이며
:ref:`sqlexpression_toplevel`\ 에 설명되어 있다::

    >>> from sqlalchemy.sql import func
    >>> stmt = session.query(Address.user_id, func.count('*').\
    ...         label('address_count')).\
    ...         group_by(Address.user_id).subquery()

``func`` 키워드는 SQL 함수를 생성하고 :class:`~sqlalchemy.orm.query.Query`\ 의 ``subquery()`` 메서드는
alias에 임베디드된 SELECT 명령을 나타내는 SQL 표현식 구조를 생성한다 (이것은 사실 ``query.statement.alias()``\ 의
축약형이다).

명령문을 만들면, 이 명령문은 ``users`` 를 위해 튜토리얼 첫 부분에서 만들었던 :class:`~sqlalchemy.schema.Table`
구조처럼 작동한다. 명령문의 컬럼은 ``c``\ 라고 하는 속성을 통해 접근할 수 있다:

.. sourcecode:: python+sql

    {sql}>>> for u, count in session.query(User, stmt.c.address_count).\
    ...     outerjoin(stmt, User.id==stmt.c.user_id).order_by(User.id):
    ...     print(u, count)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password,
            anon_1.address_count AS anon_1_address_count
    FROM users LEFT OUTER JOIN
        (SELECT addresses.user_id AS user_id, count(?) AS address_count
        FROM addresses GROUP BY addresses.user_id) AS anon_1
        ON users.id = anon_1.user_id
    ORDER BY users.id
    ('*',)
    {stop}<User(name='ed', fullname='Ed Jones', password='f8s7ccs')> None
    <User(name='wendy', fullname='Wendy Williams', password='foobar')> None
    <User(name='mary', fullname='Mary Contrary', password='xxg527')> None
    <User(name='fred', fullname='Fred Flinstone', password='blah')> None
    <User(name='jack', fullname='Jack Bean', password='gjffdd')> 2

Selecting Entities from Subqueries
----------------------------------

위에서 우리는 하위 쿼리의 컬럼을 포함하는 결과를 select했다.
만약 하위 쿼리를 개체에 매핑하려면 어떻게 해야 할까? 이 경우 매핑된 클래스의 "alias"를
하위 쿼리에 ``alisased()``\ 를 사용해서 결합하면 된다:

.. sourcecode:: python+sql

    {sql}>>> stmt = session.query(Address).\
    ...                 filter(Address.email_address != 'j25@yahoo.com').\
    ...                 subquery()
    >>> adalias = aliased(Address, stmt)
    >>> for user, address in session.query(User, adalias).\
    ...         join(adalias, User.addresses):
    ...     print(user)
    ...     print(address)
    SELECT users.id AS users_id,
                users.name AS users_name,
                users.fullname AS users_fullname,
                users.password AS users_password,
                anon_1.id AS anon_1_id,
                anon_1.email_address AS anon_1_email_address,
                anon_1.user_id AS anon_1_user_id
    FROM users JOIN
        (SELECT addresses.id AS id,
                addresses.email_address AS email_address,
                addresses.user_id AS user_id
        FROM addresses
        WHERE addresses.email_address != ?) AS anon_1
        ON users.id = anon_1.user_id
    ('j25@yahoo.com',)
    {stop}<User(name='jack', fullname='Jack Bean', password='gjffdd')>
    <Address(email_address='jack@google.com')>

Using EXISTS
------------

SQL의 EXISTS 키워드는 부울리언 오퍼레이터로 주어진 표현식이 행을 포함하고 있으면
참을 리턴한다. 이것은 join을 대신해서 많은 시나리오에서 사용될 수 있으며 연결된
테이블에 대응하는 행이 없는 행을 찾을 때에도 유용하다.

명시적 EXISTS 구조는, 아래와 같이 생겼다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.sql import exists
    >>> stmt = exists().where(Address.user_id==User.id)
    {sql}>>> for name, in session.query(User.name).filter(stmt):
    ...     print(name)
    SELECT users.name AS users_name
    FROM users
    WHERE EXISTS (SELECT *
    FROM addresses
    WHERE addresses.user_id = users.id)
    ()
    {stop}jack

:class:`~sqlalchemy.orm.query.Query`\ 는 EXISTS를 자동적으로 사용하는 몇몇 오퍼레이터가 있다.
위에서, 명령문을 :meth:`~.RelationshipProperty.Comparator.any`\ 을 사용해서
``User.addresses`` relationship을 따라 표현할 수도 있다:

.. sourcecode:: python+sql

    {sql}>>> for name, in session.query(User.name).\
    ...         filter(User.addresses.any()):
    ...     print(name)
    SELECT users.name AS users_name
    FROM users
    WHERE EXISTS (SELECT 1
    FROM addresses
    WHERE users.id = addresses.user_id)
    ()
    {stop}jack

:meth:`~.RelationshipProperty.Comparator.any`\ 는 매칭되는 행 갯수를 제한할 수 있는
조건을 취하기도 한다:

.. sourcecode:: python+sql

    {sql}>>> for name, in session.query(User.name).\
    ...     filter(User.addresses.any(Address.email_address.like('%google%'))):
    ...     print(name)
    SELECT users.name AS users_name
    FROM users
    WHERE EXISTS (SELECT 1
    FROM addresses
    WHERE users.id = addresses.user_id AND addresses.email_address LIKE ?)
    ('%google%',)
    {stop}jack

:meth:`~.RelationshipProperty.Comparator.has`\ 는
다대일 relationship을 위한 :meth:`~.RelationshipProperty.Comparator.any`\ 와 동일하다.
(여기에도 ``~`` 오퍼레이터를 달아 두어라, 이것은 "NOT"을 의미한다):

.. sourcecode:: python+sql

    {sql}>>> session.query(Address).\
    ...         filter(~Address.user.has(User.name=='jack')).all()
    SELECT addresses.id AS addresses_id,
            addresses.email_address AS addresses_email_address,
            addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE NOT (EXISTS (SELECT 1
    FROM users
    WHERE users.id = addresses.user_id AND users.name = ?))
    ('jack',)
    {stop}[]

Common Relationship Operators
-----------------------------

여기에 relationship을 기반으로하는 모든 오퍼레이터가 있다 -
각각은 사용법과 동작에 관한 전체 내용을 포함하는 각자의 API 문서에 열결되어 있다:

* :meth:`~.RelationshipProperty.Comparator.__eq__` (many-to-one "equals" comparison)::

    query.filter(Address.user == someuser)

* :meth:`~.RelationshipProperty.Comparator.__ne__` (many-to-one "not equals" comparison)::

    query.filter(Address.user != someuser)

* IS NULL (many-to-one comparison, also uses :meth:`~.RelationshipProperty.Comparator.__eq__`)::

    query.filter(Address.user == None)

* :meth:`~.RelationshipProperty.Comparator.contains` (used for one-to-many collections)::

    query.filter(User.addresses.contains(someaddress))

* :meth:`~.RelationshipProperty.Comparator.any` (used for collections)::

    query.filter(User.addresses.any(Address.email_address == 'bar'))

    # also takes keyword arguments:
    query.filter(User.addresses.any(email_address='bar'))

* :meth:`~.RelationshipProperty.Comparator.has` (used for scalar references)::

    query.filter(Address.user.has(name='ed'))

* :meth:`.Query.with_parent` (used for any relationship)::

    session.query(Address).with_parent(someuser, 'addresses')

Eager Loading
=============

이전에 ``User``\ 의 ``User.addresses``\ 컬렉션에 접근하고 SQL이 내보내졌을 때
:term:`lazy loading` 작동에 대해서 설명한 것을 기억해보자.
만약 (대부분의 경우에, 극적으로) 쿼리의 수를 줄이고 싶다면
쿼리 작동에 :term:`eager load`\ 를 적용시킬 수 있다.
SQLAlchemy는 세 가지 타입의 eager loading을 제공하며, 이중 두 가지는 자동이고,
하나는 커스텀 조건을 포함하고 있다. 세 가지 모두 :term:`query options`\ 이라 하는 함수를
통해서 호출되고 이 함수는 추가적인 지시사항(다양한 속성을 어떻게 로드할 것인가)을
:meth:`.Query.options` 메서드를 통해 :class:`.Query`\ 에 제공한다.

Subquery Load
-------------

``User.addresses``\ 가 eagerly 로드되게 지시하고 싶은 경우.
객체 집합과 연결된 컬렉션을 로드하기 위한 좋은 선택지는 :func:`.orm.subqueryload` 옵션이다.
이 옵션은 로드된 결과와 연관된 컬렉 컬렉션을 완전히 로드하는 두 번째 SELECT 명령문을 내보낸다.
"subquery"라는 이름은 :class:`.Query` 통해서 직접적으로 생성된 SELECT 명령문이 다시 사용되고
관련된 테이블에 대한 SELECT에 subquery로 임베딩 된다는 사실로부터 만들어졌다.
이것은 약간 복잡하지만 사용하기는 쉽다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.orm import subqueryload
    {sql}>>> jack = session.query(User).\
    ...                 options(subqueryload(User.addresses)).\
    ...                 filter_by(name='jack').one()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ?
    ('jack',)
    SELECT addresses.id AS addresses_id,
            addresses.email_address AS addresses_email_address,
            addresses.user_id AS addresses_user_id,
            anon_1.users_id AS anon_1_users_id
    FROM (SELECT users.id AS users_id
        FROM users WHERE users.name = ?) AS anon_1
    JOIN addresses ON anon_1.users_id = addresses.user_id
    ORDER BY anon_1.users_id, addresses.id
    ('jack',)
    {stop}>>> jack
    <User(name='jack', fullname='Jack Bean', password='gjffdd')>

    >>> jack.addresses
    [<Address(email_address='jack@google.com')>, <Address(email_address='j25@yahoo.com')>]

.. note::

   :func:`.subqueryload`\ 가
   :meth:`.Query.first`, :meth:`.Query.limit` 또는 :meth:`.Query.offset` 같은
   제한과 같이 쓰였을 때는, 정확한 결과를 보장하기 위해서 유니크한 컬럼에 대해 :meth:`.Query.order_by`\ 를
   포함하고 있어야 한다. :ref:`subqueryload_ordering`\ 를 참고하라.

Joined Load
-----------

다른 자동 eager loading 함수는 더 잘 알려져있으며 :func:`.orm.joinedload`\ 로 호출된다.
이 로딩 스타일은 JOIN(기본적으로 LEFT OUTER JOIN)을 내보내고, 관련된 객체나 컬렉션
뿐만 아니라 리드 객체까지 한 번에 로드한다. 우리는 이 방식으로 같은 ``addresses`` 컬렉션을
로드하는 것을 설명할 수 있다. - ``jack``\ 에 있는 ``User.addresses`` 컬렉션이 지금 추가되더라도, 쿼리는
상관 없이 추가 join을 내보낼 것이다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.orm import joinedload

    {sql}>>> jack = session.query(User).\
    ...                        options(joinedload(User.addresses)).\
    ...                        filter_by(name='jack').one()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password,
            addresses_1.id AS addresses_1_id,
            addresses_1.email_address AS addresses_1_email_address,
            addresses_1.user_id AS addresses_1_user_id
    FROM users
        LEFT OUTER JOIN addresses AS addresses_1 ON users.id = addresses_1.user_id
    WHERE users.name = ? ORDER BY addresses_1.id
    ('jack',)

    {stop}>>> jack
    <User(name='jack', fullname='Jack Bean', password='gjffdd')>

    >>> jack.addresses
    [<Address(email_address='jack@google.com')>, <Address(email_address='j25@yahoo.com')>]

OUTER JOIN이 두 행을 결과로 가지더라도, 우리는 여전히
하나의 ``User`` 인스턴스만 돌려받는다. 왜냐하면 :class:`.Query`\ 가 객체 아이덴티티에 기반을 둔 "uniquing" 전략을
리턴된 개체에 적용하고 있기 때문이다. 이것은 특히 join된 eager loading이 쿼리 결과에
영향을 미치지않고 적용될 수 있게 한다.

:func:`.joinedload`\ 이 오랫동안 존재해왔던 반면에 :func:`.subqueryload`\ 새로 등장한 eager loading
형태다. :func:`.joinedload`\ 는 리드 객체와 연관된 객체에 대해 하나의 행만 로드된다는 사실 때문에
다대일 relationship에 더 적합한 반면 :func:`.subqueryload`\ 는 연관된 컬렉션을 로드하는 데 더 적합한 경향이 있다.

.. topic:: ``joinedload()`` is not a replacement for ``join()``

   :func:`.joinedload`\ 로 생성된 join은 익명으로 aliased 되어서
   **쿼리 결과에 영향을 미치지 않는다**. :meth:`.Query.order_by` 또는
   :meth:`.Query.filter` 호출은 이 aliased 테이블을 참조하지 **못한다** -
   소위 "user space" join은 :meth:`.Query.join`을 사용해서 생성된다.
   :func:`.joinedload`\ 는 오로지 연관된 객체나 컬렉션이 로드되는 방식에
   최적화하는 세부 정보로 영향을 주기위해만 적용된다. 실제 결과에 영향을 주지 않고
   제거되거나 추가될 수 있다. 사용되는 방식에 대한 자세한 설명은 :ref:`zen_of_eager_loading`\ 를
   참고하라.

Explicit Join + Eagerload
-------------------------

세 번째 스타일의 eager loading은 primary 행을 찾기 위해 명시적으로 JOIN을 생성할 때와
추가 테이블을 관련된 객체나 primary 객체의 컬렉션에 적용하고 싶을 때 사용한다.
이 기능은 :func:`.orm.contains_eager` 함수를 사용해서 제공되며, 일반적으로 동일한 객체를
필터링할 필요가 있는 쿼리의 다대일 객체를 프리로딩 할 때 가장 유용하다.
아래에서 ``Address`` 행과 관련된 ``User`` 객체를 로드하고, "jack" 이름의 ``User``\ 를 필터링하고
:func:`.orm.contains_eager`\ 를 사용해서 "user" 컬럼을 ``Address.user`` 속성에 적용시키는
것을 설명했다:

.. sourcecode:: python+sql

    >>> from sqlalchemy.orm import contains_eager
    {sql}>>> jacks_addresses = session.query(Address).\
    ...                             join(Address.user).\
    ...                             filter(User.name=='jack').\
    ...                             options(contains_eager(Address.user)).\
    ...                             all()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password,
            addresses.id AS addresses_id,
            addresses.email_address AS addresses_email_address,
            addresses.user_id AS addresses_user_id
    FROM addresses JOIN users ON users.id = addresses.user_id
    WHERE users.name = ?
    ('jack',)

    {stop}>>> jacks_addresses
    [<Address(email_address='jack@google.com')>, <Address(email_address='j25@yahoo.com')>]

    >>> jacks_addresses[0].user
    <User(name='jack', fullname='Jack Bean', password='gjffdd')>

기본적으로 다양한 형태의 로딩 설정을 조정하는 방법을 포함한, eager loading에 대한 자세한 정보는
:doc:`/orm/loading_relationships`\ 를 참고하.

Deleting
========

``jack``\ 을 지우고 어떻게 진행되는지를 보자. 세션에서 객체를 삭제한 것으로 표시하고
남아있는 행이 없는지 확인하기 위해 ``count`` 쿼리를 발행할 것이다:

.. sourcecode:: python+sql

    >>> session.delete(jack)
    {sql}>>> session.query(User).filter_by(name='jack').count()
    UPDATE addresses SET user_id=? WHERE addresses.id = ?
    ((None, 1), (None, 2))
    DELETE FROM users WHERE users.id = ?
    (5,)
    SELECT count(*) AS count_1
    FROM (SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ?) AS anon_1
    ('jack',)
    {stop}0

현재까지는 이상이 없다. Jack의 ``Address`` 객체는 어떨까?

.. sourcecode:: python+sql

    {sql}>>> session.query(Address).filter(
    ...     Address.email_address.in_(['jack@google.com', 'j25@yahoo.com'])
    ...  ).count()
    SELECT count(*) AS count_1
    FROM (SELECT addresses.id AS addresses_id,
                    addresses.email_address AS addresses_email_address,
                    addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE addresses.email_address IN (?, ?)) AS anon_1
    ('jack@google.com', 'j25@yahoo.com')
    {stop}2

아직까지 남아있다! flush SQL을 분석해보면, 각 address의 ``user_id`` 컬럼이 NULL로 설정되있지만
행이 삭제되지는 않은 것을 볼 수 있다. SQLAlchemy는 cascade를 삭제를 함부로 가정하지 않는다.
당신이 직접 그렇게 하도록 명령해야 한다.

.. _tutorial_delete_cascade:

Configuring delete/delete-orphan Cascade
----------------------------------------

작동을 변경하기 위해 ``User.addresses`` relationship에 있는 **cascade** 옵션을 설정할 것이다.
SQLAlchemy는 새로운 속성과 relationship을 언제나 매핑에 추가할 수 있게
해주지만 이 경우에는 존재하는 relationship을 제거해야 하므로
매핑을 완전히 제거하고 새로 시작해야 할 필요가 있다 - 우리는 :class:`.Session`\ 을 닫을 것이다::

    >>> session.close()
    ROLLBACK


그리고 새로운 :func:`.declarative_base`\ 를 사용할 것이다::

    >>> Base = declarative_base()

그 다음 ``User`` 클래스를 선언하고, cascade 설정을 포함하는 ``addresses`` relationship을
추가할 것이다 (컨스트럭터는 생략할 것이다)::

    >>> class User(Base):
    ...     __tablename__ = 'users'
    ...
    ...     id = Column(Integer, primary_key=True)
    ...     name = Column(String)
    ...     fullname = Column(String)
    ...     password = Column(String)
    ...
    ...     addresses = relationship("Address", back_populates='user',
    ...                     cascade="all, delete, delete-orphan")
    ...
    ...     def __repr__(self):
    ...        return "<User(name='%s', fullname='%s', password='%s')>" % (
    ...                                self.name, self.fullname, self.password)

그리고 ``Address``\ 를 다시 생성한다, 이 경우 이미 ``User`` 클래스를 통해서
``Address.user`` relationship을 생성했다는 것을 명심하라::

    >>> class Address(Base):
    ...     __tablename__ = 'addresses'
    ...     id = Column(Integer, primary_key=True)
    ...     email_address = Column(String, nullable=False)
    ...     user_id = Column(Integer, ForeignKey('users.id'))
    ...     user = relationship("User", back_populates="addresses")
    ...
    ...     def __repr__(self):
    ...         return "<Address(email_address='%s')>" % self.email_address

이제 user ``jack`` 을 로드할 때 (primary key로 로드하는 :meth:`~.Query.get`\ 를 사용했다),
which loads by primary key), ``addresses`` 컬렉션에 대응하는 address를 제거하면
``Address``\ 도 제거되는 결과를 얻을 수 있다:

.. sourcecode:: python+sql

    # load Jack by primary key
    {sql}>>> jack = session.query(User).get(5)
    BEGIN (implicit)
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.id = ?
    (5,)
    {stop}

    # remove one Address (lazy load fires off)
    {sql}>>> del jack.addresses[1]
    SELECT addresses.id AS addresses_id,
            addresses.email_address AS addresses_email_address,
            addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE ? = addresses.user_id
    (5,)
    {stop}

    # only one address remains
    {sql}>>> session.query(Address).filter(
    ...     Address.email_address.in_(['jack@google.com', 'j25@yahoo.com'])
    ... ).count()
    DELETE FROM addresses WHERE addresses.id = ?
    (2,)
    SELECT count(*) AS count_1
    FROM (SELECT addresses.id AS addresses_id,
                    addresses.email_address AS addresses_email_address,
                    addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE addresses.email_address IN (?, ?)) AS anon_1
    ('jack@google.com', 'j25@yahoo.com')
    {stop}1

Jack을 삭제하면 Jack과 그 user와 연결된 남아있는 ``Address``\ 도 제거된다:

.. sourcecode:: python+sql

    >>> session.delete(jack)

    {sql}>>> session.query(User).filter_by(name='jack').count()
    DELETE FROM addresses WHERE addresses.id = ?
    (1,)
    DELETE FROM users WHERE users.id = ?
    (5,)
    SELECT count(*) AS count_1
    FROM (SELECT users.id AS users_id,
                    users.name AS users_name,
                    users.fullname AS users_fullname,
                    users.password AS users_password
    FROM users
    WHERE users.name = ?) AS anon_1
    ('jack',)
    {stop}0

    {sql}>>> session.query(Address).filter(
    ...    Address.email_address.in_(['jack@google.com', 'j25@yahoo.com'])
    ... ).count()
    SELECT count(*) AS count_1
    FROM (SELECT addresses.id AS addresses_id,
                    addresses.email_address AS addresses_email_address,
                    addresses.user_id AS addresses_user_id
    FROM addresses
    WHERE addresses.email_address IN (?, ?)) AS anon_1
    ('jack@google.com', 'j25@yahoo.com')
    {stop}0

.. topic:: More on Cascades

   cascades 설정에 대한 세부 사항은 :ref:`unitofwork_cascades`\ 에 설명되어
   있다. cascade 기능은 관계형 데이터베이스의 ``ON DELETE CASCADE`` 기능과
   원활하게 통합될 수도 있다. 자세한 내용은 :ref:`passive_deletes`\ 를
   참고하라.

.. _orm_tutorial_many_to_many:

Building a Many To Many Relationship
====================================

여기서 보너스 라운드로 이동할 것이지만, 다대다 relationship을 자랑할 것이다.
둘러보고 몇몇 다른 기능들도 살펴볼 것이다.
우리는 어플리케이션을 연관된 ``Keyword`` 항목을 가지는
``BlogPost`` 항목을 사용자가 작성하는 블로그 어플리케이션을 만들 것이다.

일반적인 다대다의 경우, 우리는 매핑되지 않은 :class:`.Table` 구조를 생성해서
연결 테이블로 활용해야 한다. 이 방식은 아래와 같다::

    >>> from sqlalchemy import Table, Text
    >>> # association table
    >>> post_keywords = Table('post_keywords', Base.metadata,
    ...     Column('post_id', ForeignKey('posts.id'), primary_key=True),
    ...     Column('keyword_id', ForeignKey('keywords.id'), primary_key=True)
    ... )

위에서 우리는 :class:`.Table`\ 를 직접 선언하는 것이 매핑된 클래스를 생성하는 것과 조금 다르다는
사실을 볼 수 있다. :class:`.Table`\ 는 컨스트럭서 함수로, 각각의 개별 :class:`.Column` 인자는
콤마로 나뉘어져 있다. :class:`.Column` 객체는 할당된 속성 이름에서 가져오는 것이 아니라 명시적으로 이름을
제공받는다.

그 다음 우리는 상호보완적인 :func:`.relationship` 구조를 사용해 ``BlogPost``\ 와 ``Keyword``\ 를 정의하며
각각은 ``post_keywords``\ 를 연결 테이블로 참조한다::

    >>> class BlogPost(Base):
    ...     __tablename__ = 'posts'
    ...
    ...     id = Column(Integer, primary_key=True)
    ...     user_id = Column(Integer, ForeignKey('users.id'))
    ...     headline = Column(String(255), nullable=False)
    ...     body = Column(Text)
    ...
    ...     # many to many BlogPost<->Keyword
    ...     keywords = relationship('Keyword',
    ...                             secondary=post_keywords,
    ...                             back_populates='posts')
    ...
    ...     def __init__(self, headline, body, author):
    ...         self.author = author
    ...         self.headline = headline
    ...         self.body = body
    ...
    ...     def __repr__(self):
    ...         return "BlogPost(%r, %r, %r)" % (self.headline, self.body, self.author)


    >>> class Keyword(Base):
    ...     __tablename__ = 'keywords'
    ...
    ...     id = Column(Integer, primary_key=True)
    ...     keyword = Column(String(50), nullable=False, unique=True)
    ...     posts = relationship('BlogPost',
    ...                          secondary=post_keywords,
    ...                          back_populates='keywords')
    ...
    ...     def __init__(self, keyword):
    ...         self.keyword = keyword

.. note::

    위의 클래스 선언은 명시적인 ``__init__()`` 메서드를 보여주고 있다.
    Declarative를 사용할 때 이것은 선택적인 부분이다!

위에서, 다대다 relationship은 ``BlogPost.keywords``\ 이다. 다대다 relationship의
기능을 정의하는 것은 ``secondary`` 키워드 인자이며 이 인자는 연결 테이블을 나타내는
:class:`~sqlalchemy.schema.Table` 객체를 참조한다.
이 테이블은 relationship의 양쪽을 참조하는 컬럼만 포함한다; 만약 자신의 primary key나 다른 테이블의 foreign key
같은 다른 컬럼을 포함하고 있다면 SQLAlchemy는 "association object"라고 하는 다른 사용 패턴을 요구한다.
이에 관해서는 :ref:`association_pattern`\ 에서 설명하고 있다.

또한 우리는 ``BlogPost`` 클래스가 ``author`` 필드를 갖기를 원한다.
우리는 한 사용자가 많은 블로그 포스트를 작성할 수 있다는 것만 제외하면 이것을 다른 양방향 relationship으로 추가할 것이다.
우리가 ``User.posts``\ 에 접근할 때, 전체 컬렉션을 다 로드하지 않도록 결과를 더 필터링할 수 있으면
좋을 것이다. 이것을 위해서 우리는 :func:`~sqlalchemy.orm.relationship`\ 의해 용인되는
``lazy='dynamic'``\ 라고 불리는 세팅을 사용할 것이다. 이 세팅은 속성의 대체 **loader strategy**\ 를
구성한다:

.. sourcecode:: python+sql

    >>> BlogPost.author = relationship(User, back_populates="posts")
    >>> User.posts = relationship(BlogPost, back_populates="author", lazy="dynamic")

새로운 테이블을 만들자:

.. sourcecode:: python+sql

    {sql}>>> Base.metadata.create_all(engine)
    PRAGMA...
    CREATE TABLE keywords (
        id INTEGER NOT NULL,
        keyword VARCHAR(50) NOT NULL,
        PRIMARY KEY (id),
        UNIQUE (keyword)
    )
    ()
    COMMIT
    CREATE TABLE posts (
        id INTEGER NOT NULL,
        user_id INTEGER,
        headline VARCHAR(255) NOT NULL,
        body TEXT,
        PRIMARY KEY (id),
        FOREIGN KEY(user_id) REFERENCES users (id)
    )
    ()
    COMMIT
    CREATE TABLE post_keywords (
        post_id INTEGER NOT NULL,
        keyword_id INTEGER NOT NULL,
        PRIMARY KEY (post_id, keyword_id),
        FOREIGN KEY(post_id) REFERENCES posts (id),
        FOREIGN KEY(keyword_id) REFERENCES keywords (id)
    )
    ()
    COMMIT

사용법은 해왔던 것에 비해서 크게 다르지 않다. Wendy에게 blog post 몇개를 추가하자:

.. sourcecode:: python+sql

    {sql}>>> wendy = session.query(User).\
    ...                 filter_by(name='wendy').\
    ...                 one()
    SELECT users.id AS users_id,
            users.name AS users_name,
            users.fullname AS users_fullname,
            users.password AS users_password
    FROM users
    WHERE users.name = ?
    ('wendy',)
    {stop}
    >>> post = BlogPost("Wendy's Blog Post", "This is a test", wendy)
    >>> session.add(post)

우리는 데이터베이스에서 키워드를 유니크하게 저장하고 있지만,
우리가 키워드가 없다는 것을 알고 있기 때문에 몇 개를 생성했다:

.. sourcecode:: python+sql

    >>> post.keywords.append(Keyword('wendy'))
    >>> post.keywords.append(Keyword('firstpost'))

이제 `firstpost` 키워드를 가진 모든 블로그 포스트를 찾을 수 있다.
우리는 ``any`` 오퍼레이터를 사용해서 키워드 문자열로 'fisrtpost'를 가지는 블로그 포스트를
찾을 수 있다::

.. sourcecode:: python+sql

    {sql}>>> session.query(BlogPost).\
    ...             filter(BlogPost.keywords.any(keyword='firstpost')).\
    ...             all()
    INSERT INTO keywords (keyword) VALUES (?)
    ('wendy',)
    INSERT INTO keywords (keyword) VALUES (?)
    ('firstpost',)
    INSERT INTO posts (user_id, headline, body) VALUES (?, ?, ?)
    (2, "Wendy's Blog Post", 'This is a test')
    INSERT INTO post_keywords (post_id, keyword_id) VALUES (?, ?)
    (...)
    SELECT posts.id AS posts_id,
            posts.user_id AS posts_user_id,
            posts.headline AS posts_headline,
            posts.body AS posts_body
    FROM posts
    WHERE EXISTS (SELECT 1
        FROM post_keywords, keywords
        WHERE posts.id = post_keywords.post_id
            AND keywords.id = post_keywords.keyword_id
            AND keywords.keyword = ?)
    ('firstpost',)
    {stop}[BlogPost("Wendy's Blog Post", 'This is a test', <User(name='wendy', fullname='Wendy Williams', password='foobar')>)]

만약 user ``wendy``\ 가 소유하고 있는 포스트를 찾고 싶으면, 우리는 부모로서 ``User`` 객체에 한정하도록 쿼리를 좁힐 수 있다:

.. sourcecode:: python+sql

    {sql}>>> session.query(BlogPost).\
    ...             filter(BlogPost.author==wendy).\
    ...             filter(BlogPost.keywords.any(keyword='firstpost')).\
    ...             all()
    SELECT posts.id AS posts_id,
            posts.user_id AS posts_user_id,
            posts.headline AS posts_headline,
            posts.body AS posts_body
    FROM posts
    WHERE ? = posts.user_id AND (EXISTS (SELECT 1
        FROM post_keywords, keywords
        WHERE posts.id = post_keywords.post_id
            AND keywords.id = post_keywords.keyword_id
            AND keywords.keyword = ?))
    (2, 'firstpost')
    {stop}[BlogPost("Wendy's Blog Post", 'This is a test', <User(name='wendy', fullname='Wendy Williams', password='foobar')>)]

또는 "dynamic" relationship인 Wendy의 ``posts`` relationship을 사용해서 거기서
바로 쿼리할 수 있다:

.. sourcecode:: python+sql

    {sql}>>> wendy.posts.\
    ...         filter(BlogPost.keywords.any(keyword='firstpost')).\
    ...         all()
    SELECT posts.id AS posts_id,
            posts.user_id AS posts_user_id,
            posts.headline AS posts_headline,
            posts.body AS posts_body
    FROM posts
    WHERE ? = posts.user_id AND (EXISTS (SELECT 1
        FROM post_keywords, keywords
        WHERE posts.id = post_keywords.post_id
            AND keywords.id = post_keywords.keyword_id
            AND keywords.keyword = ?))
    (2, 'firstpost')
    {stop}[BlogPost("Wendy's Blog Post", 'This is a test', <User(name='wendy', fullname='Wendy Williams', password='foobar')>)]

Further Reference
==================

Query Reference: :ref:`query_api_toplevel`

Mapper Reference: :ref:`mapper_config_toplevel`

Relationship Reference: :ref:`relationship_config_toplevel`

Session Reference: :doc:`/orm/session`
