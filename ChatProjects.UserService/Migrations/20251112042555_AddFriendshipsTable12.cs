using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ChatProjects.UserService.Migrations
{
    /// <inheritdoc />
    public partial class AddFriendshipsTable12 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_Friendship",
                table: "Friendship");

            migrationBuilder.RenameTable(
                name: "Friendship",
                newName: "Friendships");

            migrationBuilder.RenameIndex(
                name: "IX_Friendship_User1Id_User2Id",
                table: "Friendships",
                newName: "IX_Friendships_User1Id_User2Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Friendships",
                table: "Friendships",
                column: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_Friendships",
                table: "Friendships");

            migrationBuilder.RenameTable(
                name: "Friendships",
                newName: "Friendship");

            migrationBuilder.RenameIndex(
                name: "IX_Friendships_User1Id_User2Id",
                table: "Friendship",
                newName: "IX_Friendship_User1Id_User2Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Friendship",
                table: "Friendship",
                column: "Id");
        }
    }
}
