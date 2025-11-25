using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ChatProjects.ChatHistoryService.Migrations
{
    /// <inheritdoc />
    public partial class AddGroupFiel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Avatar",
                table: "Conversations",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "Conversations",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Avatar",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "Name",
                table: "Conversations");
        }
    }
}
