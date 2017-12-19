.. _overview_toplevel_ko:
.. _overview_ko:

========
개요
========

SQLAlchemy SQL Toolkit과 Object Relational Mapper는
데이터베이스와 파이썬으로 작업을 하기 위한 포괄적인 툴 세트다.
그리고 기능이 단독으로 쓰이거나 같이 결합해서 쓰일 수 있는 여러
영역을 가지고 있다. 주요 구성요소는 레이어별로 정리된 구성요소
의존성과 함께 아래에 설명되어 있다:

.. image:: sqla_arch_small.png

위에서 SQLAlchemy의 가장 중요한 두 부분은 **Object Relational Mapper**\ 와
**SQL Expression Language**\ 이다. SQL 표현식은 ORM에 독립적으로
사용할 수 있다. ORM을 사용할 때, SQL 표현식 언어는 객체 관계형 구성과 쿼리에서 사용되기 때문에
공개적인 대면 API의 일부로 남아있다.

.. _doc_overview_ko:

도큐먼테이션 개요
======================

도큐먼테이션은 세 섹션으로 구분되어 있다::ref:`orm_toplevel_ko`,
:ref:`core_toplevel_ko`, :ref:`dialect_toplevel`.

:ref:`orm_toplevel_ko`\ 에서는, Object Relational Mapper를 소개하고 충분히 설명한다.
새로운 사용자는 :ref:`ormtutorial_toplevel_ko`\ 부터 시작하는 것이 좋다. 만약 고 수준의
자동으로 생성되어 있는 SQL과 파이썬 객체 관리를 통해 작업하기를 원한다면 이 튜토리얼부터 진행하라.

:ref:`core_toplevel_ko`\ 에서는, SQLAlchemy의 SQL과 데이터베이스 통합에 대한 폭넓은 정보와
설명 서비스가 문서화 되어 있으며, SQL 표현식 언어의 핵심을 다룬다.
SQL 표현 언어는 ORM 패키지 특유의 독립적인 툴킷이며 ORM 패키지는 프로그램적으로 생성되고,
수정되고, 실행되며 cursor와 유사한 결과 세트를 반환하는 조작이 가능한 SQL 표현식을 구성하기
위해 사용된다. ORM의 도메인 중심 사용 모드와 반대로 이러한 표현식 언어는 스키마 중심의 사용
패러다임을 제공한다. 새로운 사용자는 :ref:`sqlexpression_toplevel`\ 부터 시작하는 것이
좋다. SQLAlchemy 엔진, 커넥션, 풀링 서비스 또한 :ref:`core_toplevel_ko`.

:ref:`dialect_toplevel`\ 에서는, 제공되는 모든 데이터베이스와 DBAPI 백엔드의 레퍼런스
도큐먼테이션을 담고 있다.

코드 예제
=============

대부분 orm과 관련된 작동하는 코드 예제는 SQLAlchemy 배포판에 포함되어 있다.
포함된 모든 예제 어플리케이션의 설명은 :ref:`examples_toplevel`\ 에 있다.

또한 wiki에 ORM과 핵심 SQLAlchemy를 모두 포함하는 다양한 예제들이 있다.
`Theatrum Chemicum <http://www.sqlalchemy.org/trac/wiki/UsageRecipes>`_\ 를 참고하라.

.. _installation_ko:

설치 가이드
==================

지원 플랫폼
-------------------

SQLAlchemy는 아래의 플랫폼에서 테스트 되었다:

* cPython version 2.7 이후, 2.xx 시리즈까지
* cPython version 3, 3.xx 시리즈 전체
* `Pypy <http://pypy.org/>`_ 2.1 이상

.. versionchanged:: 1.2
   Python 2.7은 현재 지원되는 최저 파이썬 버전이다.

현재 지원하지 않는 플랫폼에는 Jython과 IronPython이 포함된다.
Jython은 과거에는 지원되었었고 향후 릴리즈에서 Jython의 상태에 따라 또 지원될 수 있다.

지원되는 설치 방법
-------------------------------

SQLAlchemy 설치는 `setuptools <http://pypi.python.org/pypi/setuptools/>`_\ 에 기반한
표준 파이썬 방법론을 통하거나 ``setup.py``\ 를 직접 참조하거나
`pip <http://pypi.python.org/pypi/pip/>`_\ 를 사용하거나 다른 setuptools 호환 접근방식을
사용하면 된다.

.. versionchanged:: 현재 setup.py 파일은 1.1 setuptools를 요구한다;
   일반 distutils 설치는 더이상 지원되지 않는다.

pip를 통한 설치
---------------

``pip``\ 가 가능할 때, 배포판은 Pypi에서 다운로드 가능하고 한 번에 설치할 수 있다::

    pip install SQLAlchemy

이 명령은 `Python Cheese Shop <http://pypi.python.org/pypi/SQLAlchemy>`_\ 에서
**최신** SQLAlchemy 릴리즈 버전을 다운로드 하고 당신 시스템에 설치한다.

``1.2.0b1`` 같은 최신 **프리 릴리즈** 버전을 설치하려면,
pip에서 ``--pre`` 플래그를 사용하면 된다::

    pip install --pre SQLAlchemy

위의 경우에서 최신 버전이 프리릴리즈면 가장 최신 릴리즈 버전 대신에 프리릴리즈
버전이 설치될 것이다.


setup.py를 사용한 설치
----------------------------------

그렇지 않으면 ``setup.py`` 스크립트를 사용해서 배포판에서 설치할 수 있다::

    python setup.py install

.. _c_extensions_ko:

C 확장 설치
----------------------------------

SQLAlchemy는 결과 세트 처리에 추가적인 스피드 부스트를 제공하는 C 확장을 포함하고 있다.
이 확장은 cPython의 2.xx와 3.xx 시리즈 모두에서 지원된다.

``setup.py``\ 는 적합한 플랫폼이 감지되면 자동적으로 C 확장을 빌드한다.
컴파일러가 없거나 다른 이슈로 인해 C 확장의 빌드가 실패하면, 설치 프로세스는 경고
메세지를 출력하고 C 확장없이 빌드를 가동하고 완료시 최종 상태를 보고한다.

C 확장을 컴파일하려지 않고 build/install을 실행하기 위해서는
``DISABLE_SQLALCHEMY_CEXT`` 환경 변수를 지정해야 된다. 특별한
테스트 환경을 만들거나 일반 "rebuild" 매커니즘으로 해결되지 않는 호환성/빌드 이슈가 있을 때
사용할 수 있다::

  export DISABLE_SQLALCHEMY_CEXT=1; python setup.py install

.. versionchanged:: 1.1 기존의 ``--without-cextensions`` 플래그는 setuptools의
   사용되지 않는 기능에 의존하기 때문에 인스톨러에서 제거되었다.



데이터베이스 API 설치
----------------------------------

SQLAlchemy는 특정 데이터베이스를 위해 빌드된 :term:`DBAPI` 구현으로 작동하도록
설계되었으며 가장 유명한 데이터베이스에 대한 지원도 포함하고 있다.
:doc:`/dialecs/index`\ 에 있는 개별 데이터베이스 섹션은 외부 링크를 포함해 각 데이터베이스에서
사용가능한 DBAPI를 나열하고 있다.

설치된 SQLAlchemy 버전 확인
------------------------------------------

이 도큐먼테이션은 SQLAlchemy 버전 1.2을 다룬다. 만약 SQLAlchemy가 이미 설치된 시스템이면
파이썬 프롬프트에서 아래와 같이 버전을 확인하라:

.. sourcecode:: python+sql

     >>> import sqlalchemy
     >>> sqlalchemy.__version__ # doctest: +SKIP
     1.2.0

.. _migration:

1.1에서 1.2로 마이그레이션
===========================

1.1 -> 1.2에서 변경된 점은 :doc:`changelog/migration_12`\ 에서 확인할 수 있다.
