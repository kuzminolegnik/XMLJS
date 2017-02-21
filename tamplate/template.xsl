<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xmljs="http://www.xmljs.org/schema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xsi:schemaLocation="http://www.xmljs.org/schema template.xsd">

    <xsl:output method="html"
                indent="yes"
                encoding="utf-8"/>

    <xsl:template match="/">

        <xsl:element name="template">

            <xsl:call-template name="body-each-elements">
                <xsl:with-param name="elements" select="/xmljs:template/xmljs:body/*"/>
            </xsl:call-template>

        </xsl:element>

    </xsl:template>

    <!--
    Реребор всех элементов и долнейшее распределение
    #elements
    -->
    <xsl:template name="body-each-elements">
        <xsl:param name="elements"/>

        <xsl:for-each select="$elements">

            <xsl:call-template name="parse-element">
                <xsl:with-param name="element" select="."/>
            </xsl:call-template>

        </xsl:for-each>

    </xsl:template>

    <!--
    Парсим элемент и проверяем является ли этот элемент конструкцией шаблона
    #element -
    -->
    <xsl:template name="parse-element">
        <xsl:param name="element"/>

        <xsl:variable name="name-element">
            <xsl:value-of select="local-name($element)"/>
        </xsl:variable>

        <xsl:variable name="namespace-element">
            <xsl:value-of select="substring-before( name( $element ), concat( ':', local-name( $element ) ) )"/>
        </xsl:variable>

        <xsl:choose>

            <xsl:when test=" $namespace-element = 'xmljs' and $name-element = 'function' ">
                <xsl:call-template name="call-function">
                    <xsl:with-param name="name" select="$element/@name"/>
                    <xsl:with-param name="element" select="$element"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:when test=" $namespace-element = 'xmljs' and $name-element != 'function' ">
                <xsl:call-template name="call-function">
                    <xsl:with-param name="name" select="$name-element"/>
                    <xsl:with-param name="element" select="$element"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:when test=" $namespace-element = '' ">
                <xsl:call-template name="create-element">
                    <xsl:with-param name="name" select="$name-element"/>
                    <xsl:with-param name="attributes" select="$element/@*"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>

            </xsl:otherwise>

        </xsl:choose>

    </xsl:template>

    <!--
    Вызов указанной функции
    #name - название функции
    #element - элемент над которым надо совершить операцию
    -->
    <xsl:template name="call-function">
        <xsl:param name="name"/>
        <xsl:param name="element"/>

        <xsl:choose>

            <xsl:when test=" $name = 'for' ">
                <xsl:call-template name="call-for">

                    <xsl:with-param name="count">
                       <xsl:call-template name="get-param">
                           <xsl:with-param name="element" select="$element"/>
                           <xsl:with-param name="name-param" select=" 'iteration' "/>
                       </xsl:call-template>
                    </xsl:with-param>

                    <xsl:with-param name="elements" select="$element/xmljs:body" />

                </xsl:call-template>
            </xsl:when>

            <xsl:when test=" $name = 'paste' ">
                <xsl:call-template name="call-paste">

                    <xsl:with-param name="xpath">
                        <xsl:call-template name="get-param">
                            <xsl:with-param name="element" select="$element"/>
                            <xsl:with-param name="name-param" select=" 'xpath' "/>
                        </xsl:call-template>
                    </xsl:with-param>

                    <xsl:with-param name="data" select="/xmljs:template/xmljs:data"/>

                </xsl:call-template>
            </xsl:when>

        </xsl:choose>
        
    </xsl:template>

    <!--
    Создание эелемента без использования функций шаблона
    #name - название элемента
    #attributes - атрибуты создоваимого элемента
    -->
    <xsl:template name="create-element">
        <xsl:param name="name"/>
        <xsl:param name="attributes"/>

        <xsl:element name="{$name}">

            <xsl:for-each select="$attributes">

                <xsl:attribute name="{local-name(.)}">
                    <xsl:value-of select="."/>
                </xsl:attribute>

            </xsl:for-each>

            <xsl:choose>

                <xsl:when test="boolean(*)">
                    <xsl:call-template name="body-each-elements">
                        <xsl:with-param name="elements" select="*" />
                    </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:value-of select="text()" />
                </xsl:otherwise>

            </xsl:choose>

        </xsl:element>

    </xsl:template>

    <!--
    Вызов функции цикла
    #count - солличество итераций
    #elements - элементы для повторного отображения
    -->
    <xsl:template name="call-for">
        <xsl:param name="elements"/>
        <xsl:param name="count"/>

        <xsl:message>
            <xsl:value-of select="$count"/>
        </xsl:message>

        <xsl:call-template name="body-each-elements">
            <xsl:with-param name="elements" select="$elements/*"/>
        </xsl:call-template>

        <xsl:if test="number($count) > 1">
            <xsl:call-template name="call-for">
                <xsl:with-param name="elements" select="$elements"/>
                <xsl:with-param name="count" select="number($count) - 1"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>

    <!--
    Вставка значения и элемента DATA
    #xpath - строка поиска
    #data - элемент поиска
    -->
    <xsl:template name="call-paste">
        <xsl:param name="xpath"/>
        <xsl:param name="data"/>

        <xsl:variable name="inner-name">
            <xsl:choose>
                <xsl:when test="string-length( substring-before($xpath, '/') ) > 0">
                    <xsl:value-of select="substring-before($xpath, '/')"/>
                </xsl:when>
                <xsl:when test="not(string-length( substring-before($xpath, '/') ) > 0)">
                    <xsl:value-of select="$xpath"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="before-name">

            <xsl:choose>
                <xsl:when test="contains( $inner-name, '[' )">
                    <xsl:value-of select="substring-before($xpath, '[')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select=" $inner-name "/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="after-name" select="substring-after($xpath, '/')" />

        <xsl:variable name="index">
            <xsl:choose>
                <xsl:when test="contains($inner-name, '[')">
                    <xsl:value-of select="substring-before( substring-after($inner-name, '['), ']' )"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="0"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>

            <xsl:when test="boolean($before-name) and boolean($after-name)">
                <xsl:choose>

                    <xsl:when test="number($index) > 0">
                        <xsl:call-template name="call-paste">
                            <xsl:with-param name="xpath" select="$after-name"/>
                            <xsl:with-param name="data" select="$data/*[local-name(.) = $before-name][number($index)]" />
                        </xsl:call-template>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:call-template name="call-paste">
                            <xsl:with-param name="xpath" select="$after-name"/>
                            <xsl:with-param name="data" select="$data/*[local-name(.) = $before-name]" />
                        </xsl:call-template>
                    </xsl:otherwise>

                </xsl:choose>
            </xsl:when>

            <xsl:when test="boolean($before-name) and not(boolean($after-name))">
                <xsl:choose>

                    <xsl:when test="number($index) > 0">
                        <xsl:value-of select="$data/*[local-name(.) = $before-name][number($index)]"/>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:value-of select="$data/*[local-name(.) = $before-name]"/>
                    </xsl:otherwise>

                </xsl:choose>
            </xsl:when>

            <xsl:when test="not(boolean($before-name)) and not(boolean($after-name))">
                <xsl:choose>

                    <xsl:when test="number($index) > 0">
                        <xsl:value-of select="$data/*[local-name(.) = $xpath][number($index)]"/>
                    </xsl:when>

                    <xsl:otherwise>
                        <xsl:value-of select="$data/*[local-name(.) = $xpath]"/>
                    </xsl:otherwise>

                </xsl:choose>
            </xsl:when>

        </xsl:choose>

    </xsl:template>

    <!--
    Возвращает значение параметра.
    Сначало значение ищется во вложенных элементах, затем в атрибутах
    #name-param
    #element
    -->
    <xsl:template name="get-param">
        <xsl:param name="name-param"/>
        <xsl:param name="element"/>

        <xsl:choose>

            <xsl:when test="$element/xmljs:params/xmljs:param/@name = $name-param">

                <xsl:choose>
                    <xsl:when test="$element/xmljs:params/xmljs:param/xmljs:value">
                        <xsl:value-of select="$element/xmljs:params/xmljs:param/xmljs:value/."/>
                    </xsl:when>
                    <xsl:when test="$element/xmljs:params/xmljs:param/@value">
                        <xsl:value-of select="$element/xmljs:params/xmljs:param/@value"/>
                    </xsl:when>
                </xsl:choose>

            </xsl:when>

            <xsl:when test="$element/@*[name(.) = $name-param]">
                <xsl:value-of select="$element/@*[name(.) = $name-param]"/>
            </xsl:when>

            <xsl:otherwise>

            </xsl:otherwise>

        </xsl:choose>

    </xsl:template>

    <!--
    Парсим содержимое функции и подставляем значение в место переменной
    #body
    #param-name
    #param-value
    -->
    <xsl:template name="parse-inner-param">
        <xsl:param name="body"/>
        <xsl:param name="param-name"/>
        <xsl:param name="param-value"/>



    </xsl:template>

</xsl:stylesheet>