<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Feb 9, 2010</xd:p>
            <xd:p><xd:b>Author:</xd:b>Arnie Chien</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output method="xml" name="xml"/>
    <xsl:output method="text" name="text"/>
    
    <xsl:variable name="pagesFiles" select="/BookContents/PageLocations"/>
    
    <xsl:template match="/">              
        <!-- Output a file for each Section, recursively. -->
        <!--<xsl:apply-templates select="BookContents/Sections/Section"/> -->  
        <xsl:call-template name="makeSectionFile">
            <xsl:with-param name="start">0</xsl:with-param>
            <xsl:with-param name="count" select="count(BookContents/Sections/Section)"/>
            <xsl:with-param name="sections" select="BookContents/Sections/Section"/>
        </xsl:call-template> 
        
        <!-- Output a mimetype file. -->
        <xsl:result-document href="test.epub/mimetype" format="text">  
            <xsl:text>application/epub+zip</xsl:text>                            
        </xsl:result-document>
        
        <!-- Output a container file. -->
        <xsl:result-document href="test.epub/META-INF/container.xml" format="xml">  
            <xsl:text>&#10;</xsl:text>    
            <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
            <xsl:text>&#10;</xsl:text>    
            <rootfiles>
            <xsl:text>&#10;</xsl:text>    
            <rootfile full-path="OPS/hmh.opf" media-type="application/oebps-package+xml"/>
            <xsl:text>&#10;</xsl:text>    
            </rootfiles>
            </container>      
        </xsl:result-document>
            
        <!-- Output a package file. -->
        <xsl:result-document href="test.epub/OPS/hmh.opf" format="xml">  
            <xsl:text>&#10;</xsl:text>
            <package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="PrimaryID">
            <xsl:text>&#10;</xsl:text>
            <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
            <xsl:text>&#10;</xsl:text>    
            <dc:title/>
            <xsl:text>&#10;</xsl:text>
            <dc:language>en</dc:language>
            <xsl:text>&#10;</xsl:text>
            <dc:identifier id="BookId" opf:scheme="ISBN"></dc:identifier>   
            <xsl:text>&#10;</xsl:text>         
            </metadata>    
            <xsl:text>&#10;</xsl:text>    
            <manifest>
            <xsl:call-template name="makeManifest">
                <xsl:with-param name="start">0</xsl:with-param>
                <xsl:with-param name="count" select="count(BookContents/Sections/Section)"/>
            </xsl:call-template>                
            <xsl:text>&#10;</xsl:text>
            </manifest>
            <xsl:text>&#10;</xsl:text>
            <spine>
            <xsl:call-template name="makeSpine">
                <xsl:with-param name="start">0</xsl:with-param>
                <xsl:with-param name="count" select="count(BookContents/Sections/Section)"/>
            </xsl:call-template>                
            <xsl:text>&#10;</xsl:text>                
            </spine>
            <xsl:text>&#10;</xsl:text>
            </package>
        </xsl:result-document>                    
    </xsl:template>
    
    <xsl:template name="makeManifest">
        <!-- TODO include cover if cover.png is present -->
        <xsl:param name="start"/>
        <xsl:param name="count"/>
        <xsl:if test="$start &lt; $count">
            <xsl:text>&#10;</xsl:text>
            <!--
            <xsl:text>
            item id="
            </xsl:text> 
            {concat('s',$start)}" href="{concat(concat('s',$start),'.xml')}" media-type="application/xhtml+xml"/
            <xsl:text>&#10;</xsl:text>
            >
            -->
            <!--<xsl:text>-->
            <item id="{concat('s',$start)}" href="{concat(concat('s',$start),'.xml')}" media-type="application/xhtml+xml"/>
            <!--</xsl:text>-->    
            <!--<xsl:value-of select="&lt;item id='{concat('s',$start)}' href='{concat(concat('s',$start),'.xml')}' media-type='application/xhtml+xml'/&gt;"/>-->
            <!--<xsl:variable name="filePrefix" select="{concat('s',$start)}"/>
            <item id="$filePrefix" href="{concat($filePrefix,'.xml')}" media-type="application/xhtml+xml"/>-->
            <xsl:call-template name="makeManifest">
            <xsl:with-param name="start" select="$start + 1"/>
            <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="makeSpine">
        <!-- TODO include cover if cover.png is present -->
        <xsl:param name="start"/>
        <xsl:param name="count"/>
        <xsl:if test="$start &lt; $count">
            <xsl:text>&#10;</xsl:text>
            <itemref idref="{concat('s',$start)}" linear="yes"/>
            <xsl:call-template name="makeSpine">
                <xsl:with-param name="start" select="$start + 1"/>
                <xsl:with-param name="count" select="$count"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="makeSectionFile">
        <xsl:param name="start"/>
        <xsl:param name="count"/>
        <xsl:param name="sections"/>
       <xsl:if test="$start &lt; $count">               
            <xsl:result-document href="{concat('test.epub/OPS/',concat(concat('s',$start),'.xml'))}" format="xml">
                <xsl:text>&#10;</xsl:text>
                <html>
                <xsl:text>&#10;</xsl:text>
                <head><title/></head>
                <xsl:text>&#10;</xsl:text><body>           
                <xsl:for-each select="$sections[$start+1]/FlowReference">
                    <xsl:apply-templates select="document(@Source)/Flow/Paragraph"/>
                 </xsl:for-each>            
                <xsl:text>&#10;</xsl:text>
                </body>
                <xsl:text>&#10;</xsl:text>
                </html>
            </xsl:result-document>             
            <xsl:call-template name="makeSectionFile">
                <xsl:with-param name="start" select="$start + 1"/>
                <xsl:with-param name="count" select="$count"/>
                <xsl:with-param name="sections" select="$sections"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
 
<!--
    <xsl:template match="Section">
            <xsl:variable name="fileName">
                <xsl:choose>
                    <xsl:when test="boolean(@Name)">
                        <xsl:value-of select="@Name"></xsl:value-of>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>index</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:variable>            
            <xsl:result-document href="{concat(string($fileName),'.xml')}" format="xml">
                <xsl:text>&#10;</xsl:text><html>
                    <xsl:text>&#10;</xsl:text>
                    <head><title/></head>
                    <xsl:text>&#10;</xsl:text><body>           
                        <xsl:for-each select="FlowReference">
                            <xsl:apply-templates select="document(@Source)/Flow/Paragraph"/>
                        </xsl:for-each>            
                        <xsl:text>&#10;</xsl:text></body>
                    <xsl:text>&#10;</xsl:text></html>
            </xsl:result-document>  
    </xsl:template>
    -->
    
    <xsl:template match="Paragraph">
        <!--<xsl:for-each select="Words">-->
        <!--<div style='-eucalyptus-full-bleed: "on"' id='bliopage{@Page}'>-->
        <xsl:text>&#10;</xsl:text>
        <p>
        <xsl:for-each select="child::*"> <!-- could be Italic, etc. -->                     
            <xsl:for-each select="descendant-or-self::*" >
                <xsl:if test="name()='Words'">                               
                        <xsl:call-template name="getWords">
                            <xsl:with-param name="pageNum" select="number(@Page)"/>
                            <xsl:with-param name="blockNum" select="number(@Block)"/>
                            <xsl:with-param name="wordsStart" select="@Start"/>
                            <xsl:with-param name="wordsEnd" select="@End"/>
                            <xsl:with-param name="parentName" select="../name()"/>
                        </xsl:call-template>           

                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
        </p>
        <!--</div>-->
    </xsl:template>
 
    <xsl:template name="getWords">
        <xsl:param name="pageNum"/>
        <xsl:param name="blockNum"/>
        <xsl:param name="wordsStart"/>
        <xsl:param name="wordsEnd"/>
        <xsl:param name="parentName"/>
        <xsl:for-each select="$pagesFiles/PageRange">                           
            <xsl:if test="($pageNum &gt;= @Start) and ($pageNum &lt;= @End)"> <!--should it be number(@Start)?-->
                <xsl:choose>
                    <xsl:when test="$parentName='Italic'">
                        &lt;i&gt;
                    </xsl:when>
                </xsl:choose>               
                <xsl:call-template name="processPages">
                        <xsl:with-param name="pages" select="document(@Source)/Pages"/>
                        <xsl:with-param name="page" select="$pageNum"/>
                        <xsl:with-param name="block" select="$blockNum"/>
                        <xsl:with-param name="start" select="$wordsStart"/>
                        <xsl:with-param name="end" select="$wordsEnd"/>
                </xsl:call-template>                
                <xsl:choose>
                    <xsl:when test="$parentName='Italic'">
                        &lt;/i&gt;
                    </xsl:when>
                </xsl:choose>               
            </xsl:if>                    
         </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="processPages">
        <xsl:param name="pages"/>
        <xsl:param name="page"/>
        <xsl:param name="block"/>
        <xsl:param name="start"/>
        <xsl:param name="end"/>
        <xsl:for-each select="$pages/Page">
            <xsl:if test="$page = @PageIndex"> 
                <xsl:for-each select="Block">
                    <xsl:if test="$block = @ID">
                        <xsl:variable name="firstTextBlock">
                            <!-- This has now already been assigned a root node, so hard to treat as boolean. -->
                            <xsl:choose>
                                <xsl:when test="preceding-sibling::* and not(preceding-sibling::*[last()]/@Surround) and not(preceding-sibling::*[last()]/@Folio)">
                                    <xsl:value-of select="0"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="1"/>
                                </xsl:otherwise>
                            </xsl:choose>                                        
                        </xsl:variable>
                        <xsl:for-each select="Word">
                            <xsl:choose>
                                <xsl:when test="(boolean($start))">
                                    <xsl:if test="(@ID &gt;= number($start)) and (@ID &lt;= number($end))">                                                                                                                         
                                        <xsl:if test="@ID = 0">                                                                                 
                                            <xsl:if test="(../@ID = 0) or ($firstTextBlock = 1)">   
                                                <a id='bliopage{$page}'/>
                                            </xsl:if>                       
                                        </xsl:if>                                         
                                        <xsl:value-of select="@Text"/>
                                        <xsl:text>&#160;</xsl:text>                                       
                                    </xsl:if>
                                </xsl:when>
                                <xsl:otherwise>     
                                    <xsl:if test="@ID = 0">                                                                                 
                                        <xsl:if test="(../@ID = 0) or ($firstTextBlock = 1)">   
                                            <a id='bliopage{$page}'/>
                                        </xsl:if>                       
                                    </xsl:if> 
                                    <xsl:value-of select="@Text"/>
                                    <xsl:text>&#160;</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>                        
                    </xsl:if>
                    
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
