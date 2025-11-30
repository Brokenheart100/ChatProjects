using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ChatProjects.ChatHistoryService.Migrations
{
    /// <inheritdoc />
    public partial class AddParticipantsNavigation1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Role",
                table: "Participants",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Role",
                table: "Participants");
        }
    }
}
