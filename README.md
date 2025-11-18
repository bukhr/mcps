# Model Context Protocol servers

Este repositorio es una colección de implementaciones de servidores Model Context Protocol (MCP) desarrollados por Buk. Los MCPs permiten a los modelos de IA acceder a servicios externos y ejecutar acciones en ellos de forma estructurada y segura.

## ¿Qué es un MCP?

Model Context Protocol (MCP) es un protocolo que permite a los modelos de IA interactuar con sistemas externos, proporcionando una interfaz estandarizada para acceder a datos y ejecutar acciones en diferentes servicios y plataformas.

## Tecnologías utilizadas

Los servidores de este repositorio están desarrollados con:

- [Ruby MCP SDK](https://github.com/modelcontextprotocol/ruby-sdk): SDK oficial para la implementación de servidores MCP en Ruby.
- Ruby 3.2+: Versión mínima requerida para ejecutar los servidores.

## Implementaciones disponibles

- [Jenkins MCP](jenkins/): Permite interactuar con servidores Jenkins para obtener información sobre builds y logs de ejecución.

## Requisitos generales

- Ruby 3.2 o superior
- Bundler
- Acceso a los servicios correspondientes para cada implementación

## Instalación general

1. Clona este repositorio:

   ```bash
   git clone https://github.com/bukhr/mcps.git
   cd mcps
   ```

2. Para cada servidor MCP que desees utilizar, sigue las instrucciones específicas en su respectiva carpeta.

## Configuración

Cada servidor MCP tiene su propia configuración específica. Consulta el README en cada carpeta de implementación para obtener instrucciones detalladas.

## Contribución

Agradecemos las contribuciones a este proyecto. Si deseas contribuir:

1. Crea un fork del repositorio
2. Crea una rama para tu funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. Desarrolla tu implementación siguiendo el estilo del código existente
4. Asegúrate de incluir pruebas para tu código
5. Actualiza la documentación según sea necesario
6. Envía un Pull Request con tus cambios

## Licencia

Este proyecto está licenciado bajo la [Licencia MIT](LICENSE).

## Contacto

Para preguntas o soporte relacionado con este repositorio, puedes contactar al equipo de Ingeniería de Buk.
