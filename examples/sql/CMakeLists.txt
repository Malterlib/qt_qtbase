# Generated from sql.pro.

if(NOT TARGET Qt::Widgets)
    return()
endif()
add_subdirectory(books)
add_subdirectory(drilldown)
add_subdirectory(cachedtable)
add_subdirectory(querymodel)
add_subdirectory(relationaltablemodel)
add_subdirectory(sqlwidgetmapper)
add_subdirectory(tablemodel)
if(TARGET Qt::Xml)
    add_subdirectory(masterdetail)
endif()

if(NOT (CMAKE_CROSSCOMPILING OR QT_FORCE_NO_TOOLS)) # special case
    add_subdirectory(sqlbrowser)
endif()
